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

pub const Task = struct {
    status: TaskStatus,
    state: *anyopaque,
    fun: *const fn (*anyopaque) TaskStepRes,

    const Self = @This();

    pub fn step(self: *Self) TaskStepRes {
        return self.fun(self.state);
    }

    pub fn init(state_ptr: anytype, comptime fun: fn (@TypeOf(state_ptr)) TaskStepRes) Self {
        const Ptr = @TypeOf(state_ptr);

        const gen = struct {
            fn wrapper(state: *anyopaque) TaskStepRes {
                const ptr: Ptr = @ptrCast(@alignCast(state));
                return fun(ptr);
            }
        };

        return .{ .fun = gen.wrapper, .state = state_ptr, .status = .Ready };
    }
};
