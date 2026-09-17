const root = @import("root.zig");
const hub_mod = root.hub;

const SyncRes = hub_mod.SyncRes;

pub const TaskId = usize;

pub const TaskStatus = enum {
    Running,
    Blocked,
    Finished,
    Ready,
};

pub const HubReqStatus = enum { NW, W };

pub const TaskStepRes = union(enum) {
    const Request = struct {
        status: HubReqStatus,
        hub: *anyopaque,
        fun: *const fn (*anyopaque, TaskId, *anyopaque) anyerror!SyncRes,
        id: TaskId,
        data: *anyopaque,
    };
    Continue,
    Finish,
    Get: Request,
    Put: Request,

    pub fn makePutReq(status: HubReqStatus, hub_ptr: anytype, id: TaskId, data: *@TypeOf(hub_ptr.*).PutTy) TaskStepRes {
        const Ptr = @TypeOf(hub_ptr);
        const Data = @TypeOf(data);

        const gen = struct {
            fn wrapper(hub: *anyopaque, task_id: TaskId, req_data: *anyopaque) anyerror!SyncRes {
                const ptr: Ptr = @ptrCast(@alignCast(hub));
                const data_typed: Data = @ptrCast(@alignCast(req_data));
                return ptr.put(task_id, data_typed.*);
            }
        };

        return .{ .Put = .{ .fun = gen.wrapper, .id = id, .data = data, .hub = hub_ptr, .status = status } };
    }

    pub fn makeGetReq(status: HubReqStatus, hub_ptr: anytype, id: TaskId, data: *@TypeOf(hub_ptr.*).GetTy) TaskStepRes {
        const Ptr = @TypeOf(hub_ptr);
        const Data = @TypeOf(data);

        const gen = struct {
            fn wrapper(hub: *anyopaque, task_id: TaskId, req_data: *anyopaque) anyerror!void {
                const ptr: Ptr = @ptrCast(@alignCast(hub));
                const data_typed: Data = @ptrCast(@alignCast(req_data));
                return ptr.get(task_id, data_typed);
            }
        };

        return .{ .Get = .{ .fun = gen.wrapper, .id = id, .data = data, .hub = hub_ptr, .status = status } };
    }
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
