from line_profiler_pycharm import profile

@profile
def test_work():
    for i in range(10000):
        _ = i ** 2

test_work()