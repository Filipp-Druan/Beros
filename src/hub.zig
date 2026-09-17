const root = @import("root.zig");
const task = root.task;
const TaskId = task.TaskId;

fn WaitingList(ty: type, comptime size: usize) type {
    const Pair = struct { id: TaskId, data: ty };

    if (size == 0) return struct {
        const Self = @This();
        pub fn init() Self {
            return Self{};
        }
        pub fn add(self: *Self, pair: Pair) !void {
            _ = self;
            _ = pair;
        }
    };

    return struct {
        const Self = @This();

        tasks: [size]Pair,
        current: usize = 0,

        pub fn init() Self {
            return Self{ .tasks = [_]Pair{0} ** size };
        }

        pub fn add(self: *Self, pair: Pair) !void {
            if (self.current == self.tasks.len) {
                return error.OutOfCapacity;
            }

            self.tasks[self.current] = pair;
            self.current += 1;
        }

        pub fn delete(self: *Self, index: usize) !void {
            if (index >= self.current) return error.OutOfCapacity;

            for (index..(self.current - 1), (index + 1)..self.current) |target, source| {
                self.tasks[target] = self.tasks[source];
            }
            self.current -= 1;
        }
    };
}

pub fn Hub(state_ty: type, get_ty: type, get_size: usize, put_ty: type, put_size: usize) type {
    return struct {
        pub const PutTy = put_ty;
        pub const GetTy = get_ty;
        const Self = @This();

        state: state_ty,
        get_pred: *const fn (*Self, get_ty, TaskId) anyerror!bool,
        get_action: *const fn (*Self, get_ty, TaskId) anyerror!void,
        put_pred: *const fn (*Self, put_ty, TaskId) anyerror!bool,
        put_action: *const fn (*Self, put_ty, TaskId) anyerror!void,

        get_waiting_list: WaitingList(get_ty, get_size),
        put_waiting_list: WaitingList(put_ty, put_size),

        pub fn put(self: *Self, id: TaskId, data: put_ty) anyerror!void {
            if (try self.put_pred(self, data, id)) {
                try self.put_action(self, data, id);
                return;
            }

            try self.put_waiting_list.add(.{ .data = data, .id = id });
            return;
        }

        pub fn get(self: *Self, id: TaskId, data: get_ty) anyerror!void {
            if (try self.get_pred(self, data, id)) {
                self.get_action(self, data, id);
                return;
            }

            try self.get_waiting_list.add(.{ .data = data, .id = id });
            return;
        }
        pub fn emptyGetPred(self: *Self, data: get_ty, id: TaskId) anyerror!bool {
            _ = self;
            _ = data;
            _ = id;
            unreachable;
        }

        pub fn emptyPutPred(self: *Self, data: put_ty, id: TaskId) anyerror!bool {
            _ = self;
            _ = data;
            _ = id;
            unreachable;
        }

        pub fn emptyGetAction(self: *Self, data: get_ty, id: TaskId) anyerror!void {
            _ = self;
            _ = data;
            _ = id;
            unreachable;
        }

        pub fn emptyPutAction(self: *Self, data: put_ty, id: TaskId) anyerror!void {
            _ = self;
            _ = data;
            _ = id;
            unreachable;
        }

        pub fn alwaysTrue(self: *Self, data: put_ty, id: TaskId) anyerror!bool {
            _ = self;
            _ = data;
            _ = id;
            return true;
        }

        pub fn initPut(
            state: state_ty,
            put_pred: *const fn (*Self, put_ty, TaskId) anyerror!bool,
            put_action: *const fn (*Self, put_ty, TaskId) anyerror!void,
        ) Self {
            return .{
                .state = state,
                .put_pred = put_pred,
                .put_action = put_action,
                .get_pred = emptyGetPred,
                .get_action = emptyGetAction,
                .put_waiting_list = WaitingList(put_ty, put_size).init(),
                .get_waiting_list = WaitingList(get_ty, put_size).init(),
            };
        }
    };
}
