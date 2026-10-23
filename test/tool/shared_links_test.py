import unittest

from tool.configure_shared_links import shared_link_host


class SharedLinkConfigurationTests(unittest.TestCase):
    def test_uses_the_same_public_host_as_the_api(self):
        self.assertEqual(shared_link_host("https://API.example.com/"), "api.example.com")

    def test_rejects_urls_that_cannot_be_used_as_an_associated_domain(self):
        for value in (
            "", "http://example.com", "https://example.com/path",
            "https://example.com?secret=value", "https://example.com/#fragment",
            "https://user:pass@example.com", "https://example.com:8443",
            "https://[invalid", "https://example.com:invalid",
        ):
            with self.subTest(value=value), self.assertRaises(ValueError):
                shared_link_host(value)
