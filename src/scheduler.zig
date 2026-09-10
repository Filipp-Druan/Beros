const root = @import("root.zig");
const Task = root.task.Task;
const TaskId = root.task.TaskId;

// В этом файле находится планировщик задач.

pub fn Scheduler(comptime State: type) type {
    const TaskTy = Task(State);
    return struct {
        tasks: []TaskTy,
        current_task_num: TaskId,

        const Self = @This();

        pub fn init(tasks: []TaskTy) Self {
            return .{ .tasks = tasks, .current_task_num = 0 };
        }

        fn int_current_task_num(self: *Self) void {
            self.current_task_num = (self.current_task_num + 1) % self.tasks.len;
        }

        pub fn step(self: *Self) void {
            while (true) {
                var current_task = &self.tasks[self.current_task_num];
                if (current_task.status == .Ready) {
                    current_task.status = .Running;
                    const res = current_task.step();

                    switch (res) {
                        .Continue => {
                            current_task.status = .Ready;
                        },
                        .Block => {
                            current_task.status = .Blocked;
                        },
                    }
                    self.int_current_task_num();
                    break;
                }
            }
        }
    };
}
