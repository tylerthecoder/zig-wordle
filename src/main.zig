const std = @import("std");
const wordfile = "./words.txt";

pub fn main() !void {
    const file = try std.fs.cwd().openFile(wordfile, .{});
    defer file.close();

    const file_size = try file.getEndPos();

    // make allocator for the file
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    _ = try file.readAll(buffer);

    std.debug.print("Hello World, {s} \n", .{buffer});

    // pick a random element from the buffer.
    var prng = std.rand.DefaultPrng.init(4173998);
    const rng = prng.random();

    var word_count: u32 = 0;
    for (buffer) |char| {
        if (char == '\n') {
            word_count += 1;
        }
    }

    const random_index = rng.intRangeAtMost(u32, 0, word_count - 1);

    const word_loc = random_index * 6;

    const word = buffer[word_loc .. word_loc + 6];

    std.debug.print("Random index: {d}\n", .{random_index});
    std.debug.print("Random word: {s}", .{word});

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    var input: [7]u8 = undefined;

    const stdin = std.io.getStdIn().reader();

    _ = try stdin.readUntilDelimiter(&input, '\n');

    try stdout.print("Hello {s}\n", .{input});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
