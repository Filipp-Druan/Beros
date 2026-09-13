const std = @import("std");

const root = @import("root.zig");
const task = root.task;
const scheduler_module = root.scheduler;

fn worker1(state: *u32) task.TaskStepRes {
    std.debug.print("worker1: state = {}\n", .{state.*});
    state.* = state.* + 1;
    return .Continue;
}

fn worker2(state: *u32) task.TaskStepRes {
    std.debug.print("worker2: state = {}\n", .{state.*});
    state.* = state.* + 1;
    return if (state.* < 3) .Continue else .Block;
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
        // std.debug.print("tasks = {any}\n\n", .{scheduler.tasks});
    }
}
