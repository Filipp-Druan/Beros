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

pub const HubConstructor = union(enum) {
    Put: struct {
        state_ty: type,
        put_ty: type,
        put_size: usize,
    },

    Get: struct {
        state_ty: type,
        get_ty: type,
        get_size: usize,
    },

    PutGet: struct {
        state_ty: type,
        get_ty: type,
        get_size: usize,
        put_ty: type,
        put_size: usize,
    },
};

pub fn Hub(constructor: HubConstructor) type {
    return switch (constructor) {
        .Put => |c| struct {
            const Self = @This();
            pub const PutTy = c.put_ty;

            state: c.state_ty,
            put_pred: *const fn (*Self, c.put_ty, TaskId) anyerror!bool,
            put_action: *const fn (*Self, c.put_ty, TaskId) anyerror!void,
            put_waiting_list: WaitingList(c.put_ty, c.put_size),

            pub fn put(self: *Self, id: TaskId, data: c.put_ty) anyerror!void {
                if (try self.put_pred(self, data, id)) {
                    try self.put_action(self, data, id);
                    return;
                }

                try self.put_waiting_list.add(.{ .data = data, .id = id });
                return;
            }
        },
        .Get => |c| struct {
            const Self = @This();
            pub const GetTy = c.get_ty;

            state: c.state_ty,
            get_pred: *const fn (*Self, c.get_ty, TaskId) anyerror!bool,
            get_action: *const fn (*Self, c.get_ty, TaskId) anyerror!void,
            get_waiting_list: WaitingList(c.get_ty, c.get_size),

            pub fn get(self: *Self, id: TaskId, data: c.get_ty) anyerror!void {
                if (try self.get_pred(self, data, id)) {
                    self.get_action(self, data, id);
                    return;
                }

                try self.get_waiting_list.add(.{ .data = data, .id = id });
                return;
            }
        },
        .PutGet => |c| struct {
            pub const PutTy = c.put_ty;
            pub const GetTy = c.get_ty;
            const Self = @This();
            state: c.state_ty,
            put_pred: *const fn (*Self, c.put_ty, TaskId) anyerror!bool,
            put_action: *const fn (*Self, c.put_ty, TaskId) anyerror!void,
            put_waiting_list: WaitingList(c.put_ty, c.put_size),
            get_pred: *const fn (*Self, c.get_ty, TaskId) anyerror!bool,
            get_action: *const fn (*Self, c.get_ty, TaskId) anyerror!void,
            get_waiting_list: WaitingList(c.get_ty, c.get_size),

            pub fn put(self: *Self, id: TaskId, data: c.put_ty) anyerror!void {
                if (try self.put_pred(self, data, id)) {
                    try self.put_action(self, data, id);
                    return;
                }

                try self.put_waiting_list.add(.{ .data = data, .id = id });
                return;
            }

            pub fn get(self: *Self, id: TaskId, data: c.get_ty) anyerror!void {
                if (try self.get_pred(self, data, id)) {
                    self.get_action(self, data, id);
                    return;
                }

                try self.get_waiting_list.add(.{ .data = data, .id = id });
                return;
            }
        },
    };
}
