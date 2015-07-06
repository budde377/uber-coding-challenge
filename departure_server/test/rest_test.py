from departure_server.server.rest import Handler, NoSuchFunctionException

__author__ = 'budde'
import unittest


class TestHandler(unittest.TestCase):
    def setUp(self):
        super().setUp()
        self.handler_name = "HandlerName"
        self.handler = Handler(self.handler_name)
        self.call_stack = []
        self.return_value = "success"

    def test_init_sets_name(self):
        self.assertEqual(self.handler_name, self.handler.name)

    def test_handle_handles(self):
        self.handler.add_function('f', self.caller)
        self.assertEqual(self.return_value, self.handler.handle(["f"]))
        self.assertEqual([(["f"], {})], self.call_stack)

    def test_handle_on_handlers(self):
        handler = self.handler.add_handler('f')
        handler.add_function("g", self.caller)
        self.assertEqual(self.return_value, self.handler.handle(["f", "g"]))
        self.assertEqual([(["g"], {})], self.call_stack)

    def test_wildcard_name_is_wild(self):
        self.handler.add_function("*", self.caller)
        self.handler.handle(["a"])
        self.handler.handle(["b"])
        self.assertEqual([(["a"], {}), (["b"], {})], self.call_stack)

    def test_exception_on_missing_function(self):
        with self.assertRaises(NoSuchFunctionException):
            self.handler.handle("a")

    def test_exception_on_short_name(self):
        self.handler.add_handler('a').add_function('b', self.caller)
        with self.assertRaises(NoSuchFunctionException):
            self.handler.handle(['a'])

    def test_add_handler_twice_reuses_instance(self):
        self.handler.add_handler('a').add_function('f', self.caller)
        self.handler.add_handler('a').add_function('g', self.caller)
        self.assertEqual(self.return_value, self.handler.handle(['a', 'f']))
        self.assertEqual(self.return_value, self.handler.handle(['a', 'g']))

    def caller(self, name, inp):
        self.call_stack.append((name, inp))
        return self.return_value

