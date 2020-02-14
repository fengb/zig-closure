const any = c_void;

fn Closure(comptime Return: type) type {
    return struct {
        func: fn (args: *const any) Return,
        args: *const any,

        fn call(self: @This()) Return {
            return self.func(self.args);
        }
    };
}

fn Context(comptime func: var, comptime Args: type) type {
    return struct {
        const Self = @This();
        const Return = @typeInfo(@TypeOf(func)).Fn.return_type orelse void;

        pub const wrappedFunc = func;
        wrapped_args: WrappedArgs,

        const WrappedArgs = union {
            data: Args,

            // This needs to exist to force a zero sized struct (comptime literal) to exist at runtime
            _force_real: usize,
        };

        pub fn init(args: Args) Self {
            return .{ .wrapped_args = .{ .data = args } };
        }

        fn wrapper(raw: *const any) Return {
            const wrapped_args = @ptrCast(*const WrappedArgs, @alignCast(@alignOf(WrappedArgs), raw));
            return @call(.{}, wrappedFunc, wrapped_args.data);
        }

        pub fn closure(self: *const Self) Closure(Return) {
            return .{ .func = wrapper, .args = @ptrCast(*const any, &self.wrapped_args) };
        }
    };
}

fn bind(comptime func: var, args: var) Context(func, @TypeOf(args)) {
    return Context(func, @TypeOf(args)).init(args);
}
