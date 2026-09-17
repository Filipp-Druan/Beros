const std = @import("std");

const root = @import("root.zig");
const task = root.task;
const scheduler_module = root.scheduler;

const one: u32 = 1;
const two: u32 = 2;
const three: u32 = 3;
const num_13: u32 = 13;
const num_26: u32 = 26;

// Задача 1: Только ВКЛЮЧАЕТ светодиод
fn worker1(state: *u32) task.TaskStepRes {
    state.* += 1;
    std.debug.print("w1 = {}\n", .{state.*});
    return .Continue; // Эта задача работает вечно
}

// Задача 2: Только ВЫКЛЮЧАЕТ светодиод
fn worker2(state: *u32) task.TaskStepRes {
    state.* += 1;

    std.debug.print("w2 = {}\n", .{state.*});

    if (state.* >= 3) {
        return .Block; // Переходим в статус TaskStatus.Blocked
    }

    return .Continue;
}

pub fn main() !void {
    var count_1: u32 = 0;
    var count_2: u32 = 0;

    var tasks = [_]task.Task{
        task.Task.init(&count_1, worker1),
        task.Task.init(&count_2, worker2),
    };
    var scheduler = scheduler_module.Scheduler.init(&tasks);

    for (0..10) |_| {
        _ = try scheduler.step();
    }
}
