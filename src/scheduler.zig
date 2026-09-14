const root = @import("root.zig");
const Task = root.task.Task;
const TaskId = root.task.TaskId;

// В этом файле находится планировщик задач.

const SchedulerError = error{ AllTasksBlocked, TaskArrayEmpty };

pub const Scheduler = struct {
    tasks: []Task,
    current_task_id: TaskId,

    const Self = @This();

    pub fn init(tasks: []Task) Self {
        return .{ .tasks = tasks, .current_task_id = 0 };
    }

    fn int_current_task_id(self: *Self) void {
        self.current_task_id = (self.current_task_id + 1) % self.tasks.len;
    }

    fn find_next_ready(self: *Self) !TaskId {
        if (self.tasks.len == 0) return SchedulerError.TaskArrayEmpty;
        var counter = self.current_task_id;
        while (true) {
            if (self.tasks[counter].status == .Ready) return counter;
            counter = (counter + 1) % self.tasks.len;
            if (counter == self.current_task_id) return SchedulerError.AllTasksBlocked;
        }
    }

    // Эта функция выполняет следующую готовую к выполнению задачу. Если все задачи заблокированы, возвращается ошибка.
    pub fn step(self: *Self) !void {
        const next_task_id = try self.find_next_ready();

        var next_task = &self.tasks[next_task_id];
        next_task.status = .Running;

        switch (next_task.step()) {
            .Continue => next_task.status = .Ready,
            .Block => next_task.status = .Blocked,
        }

        self.current_task_id = next_task_id;
        self.int_current_task_id();
    }
};
