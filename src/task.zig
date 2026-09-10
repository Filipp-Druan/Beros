pub const TaskId = usize;

pub const TaskStatus = enum {
    Running,
    Blocked,
    Ready,
};

pub const TaskStepRes = enum {
    Continue,
    Block,
};

pub fn Task(comptime State: type) type {
    return struct {
        status: TaskStatus,
        state: State,
        fun: fun_ty,

        const fun_ty = *const fn (*State) TaskStepRes;

        const Self = @This();

        pub fn step(self: *Self) TaskStepRes {
            return self.fun(&self.state);
        }

        pub fn init(state: State, fun: fun_ty) Self {
            return .{ .fun = fun, .state = state, .status = .Ready };
        }
    };
}
