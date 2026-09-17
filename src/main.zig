const std = @import("std");

const root = @import("root.zig");
const task = root.task;
const scheduler_module = root.scheduler;
const hub_module = root.hub;
const Hub = hub_module.Hub;
const TaskId = task.TaskId;

const WriteHub = Hub(void, void, 0, u32, 0);

fn whPut(wh: *WriteHub, massage: u32, id: TaskId) anyerror!void {
    _ = wh;
    std.debug.print("worker {} = {}\n", .{ id, massage });
}

var write_hub = WriteHub.initPut({}, WriteHub.alwaysTrue, whPut);

// Задача 1: Только ВКЛЮЧАЕТ светодиод
fn worker1(state: *u32) task.TaskStepRes {
    state.* += 1;
    return .makePutReq(.NW, &write_hub, 0, state); // Эта задача работает вечно
}

// Задача 2: Только ВЫКЛЮЧАЕТ светодиод
fn worker2(state: *u32) task.TaskStepRes {
    state.* += 1;

    if (state.* >= 3) {
        return .Finish; // Переходим в статус TaskStatus.Blocked
    }

    return .makePutReq(.NW, &write_hub, 1, state);
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
