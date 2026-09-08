pub const TaskId = u32;

pub const TaskStatus = enum {
    Running,
    Blocked,
    Ready,
};

pub fn Task(state: type) type {
    return struct {
        status: TaskStatus,
        state: state,
        fun: *fn (state) state,
    };
}
