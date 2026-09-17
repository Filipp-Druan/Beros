const root = @import("root.zig");
const task = root.task;
const scheduler_module = root.scheduler;

const RCC_AHB1ENR: *volatile u32 = @ptrFromInt(0x40023830); // Регистр включения тактирования портов
const GPIOC_MODER: *volatile u32 = @ptrFromInt(0x40020800); // Режим работы пинов Порта C
const GPIOC_ODR: *volatile u32 = @ptrFromInt(0x40020814); // Регистр выходных данных Порта C

const one: u32 = 1;
const two: u32 = 2;
const three: u32 = 3;
const num_13: u32 = 13;
const num_26: u32 = 26;

// Инициализация GPIO для светодиода
fn init_led() void {
    // 1. Включаем тактирование Порта C (записываем 1 в 2-й бит регистра RCC_AHB1ENR)

    RCC_AHB1ENR.* |= (one << two);

    // 2. Настраиваем пин PC13 на режим вывода (Output)
    // В регистре MODER каждые 2 бита отвечают за один пин. Для 13-го пина это биты 27:26.
    // Значение 01 означает "General purpose output mode".
    GPIOC_MODER.* &= ~(three << num_26); // Очищаем биты 27:26
    GPIOC_MODER.* |= (one << num_26); // Устанавливаем режим вывода (01)
}

// Простейшая функция задержки
fn delay() void {
    var i: u32 = 0;
    while (i < 1_000_000) : (i += 1) {
        // Заставляем компилятор не оптимизировать пустой цикл
        asm volatile ("nop");
    }
}

// Задача 1: Только ВКЛЮЧАЕТ светодиод
fn worker1(state: *u32) task.TaskStepRes {
    state.* += 1;

    // Подаем низкий уровень (0), чтобы зажечь светодиод BlackPill
    GPIOC_ODR.* &= ~(one << num_13);

    delay();
    return .Continue; // Эта задача работает вечно
}

// Задача 2: Только ВЫКЛЮЧАЕТ светодиод
fn worker2(state: *u32) task.TaskStepRes {
    state.* += 1;

    // Подаем высокий уровень (1), чтобы погасить светодиод
    GPIOC_ODR.* |= (one << num_13);

    delay();

    // Если задача выполнилась 3 раза, блокируем её
    if (state.* >= 5) {
        return .Block; // Переходим в статус TaskStatus.Blocked
    }

    return .Continue;
}

// ======= СЮДА ВОЗВРАЩАЕМ ТАБЛИЦУ ВЕКТОРОВ =======
// Она обязана лежать в самом начале секции .text, что мы указали в stm32f401.ld
export const vector_table linksection(".text._start") = extern struct {
    stack_pointer: *anyopaque = @ptrFromInt(0x20010000), // Конец RAM для STM32F401 (0x20000000 + 64КБ)
    reset_handler: *const fn () callconv(.c) noreturn = &_start,
}{};

export fn _start() noreturn {
    // Инициализируем светодиод перед запуском планировщика
    init_led();

    var count_1: u32 = 0;
    var count_2: u32 = 0;

    var tasks = [_]task.Task{
        task.Task.init(&count_1, worker1),
        task.Task.init(&count_2, worker2),
    };
    var scheduler = scheduler_module.Scheduler.init(&tasks);

    while (true) {
        scheduler.step() catch |err| switch (err) {
            else => {
                GPIOC_ODR.* &= ~(one << num_13); // Включаем светодиод (0)
                while (true) {}
            },
        };
    }
    return 0;
}
