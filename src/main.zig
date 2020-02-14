fn Closure(comptime Return: type) type {
    return struct {
        func: fn (args: ?*const c_void) callconv(.C) Return,
        args: *const c_void,

        fn c_args(self: @This()) *c_void {
            const nukular = @ptrToInt(self.args);
            return @intToPtr(*c_void, nukular);
        }

        fn call(self: @This()) Return {
            return self.func(self.args);
        }
    };
}

fn Context(comptime func: var, comptime Args: type) type {
    const FnInfo = @typeInfo(@TypeOf(func)).Fn;
    if (FnInfo.is_generic) @compileError("TODO: support generic functions");

    return struct {
        const Self = @This();
        const Return = FnInfo.return_type orelse void;

        pub const wrappedFunc = func;
        wrapped_args: WrappedArgs,

        const WrappedArgs = union {
            data: Args,

            // This needs to exist to force a zero sized tuple (comptime literal) to exist at runtime
            _force_real: usize,
        };

        pub fn init(args: Args) Self {
            return .{ .wrapped_args = .{ .data = args } };
        }

        fn wrapper(raw: ?*const c_void) callconv(.C) Return {
            const wrapped_args = @ptrCast(*const WrappedArgs, @alignCast(@alignOf(WrappedArgs), raw));
            return @call(.{}, wrappedFunc, wrapped_args.data);
        }

        pub fn bind(self: *const Self) Closure(Return) {
            return .{ .func = wrapper, .args = @ptrCast(*const c_void, &self.wrapped_args) };
        }
    };
}

fn initContext(comptime func: var, args: var) Context(func, @TypeOf(args)) {
    return Context(func, @TypeOf(args)).init(args);
}

const std = @import("std");
test "simple" {
    const ctx0 = initContext(std.mem.alignForward, .{ 1, 8 });
    const closure0 = ctx0.bind();
    std.testing.expectEqual(closure0.call(), 8);

    const ctx1 = initContext(std.mem.alignForward, .{ 1, 4 });
    const closure1 = ctx1.bind();
    std.testing.expectEqual(closure1.call(), 4);
}

test "c" {
    const c = @cImport({
        @cInclude("test.h");
    });
    const ctx0 = initContext(std.mem.alignForward, .{ 1, 8 });
    const closure0 = ctx0.bind();
    std.testing.expectEqual(closure0.call(), c.invoke(closure0.func, closure0.c_args()));
}
