const std = @import("std");

const root = @import("root.zig");
const task = root.task;
const scheduler = root.scheduler;

const State = u32;

fn worker1(state: *State) task.TaskStepRes {
    std.debug.print("worker1: state = {}\n", .{state.*});
    state.* = state.* + 1;
    return .Continue;
}

fn worker2(state: *State) task.TaskStepRes {
    std.debug.print("worker2: state = {}\n", .{state.*});
    state.* = state.* + 2;
    return .Continue;
}

pub fn main() !void {
    var tasks = comptime [_]task.Task(State){
        task.Task(State).init(0, worker1),
        task.Task(State).init(0, worker2),
    };
    var sched = scheduler.Scheduler(State).init(&tasks);

    for (0..10) |_| {
        _ = sched.step();
    }
}
