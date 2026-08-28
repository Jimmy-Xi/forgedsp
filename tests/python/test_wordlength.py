import unittest

from forgedsp_model import search_wordlengths


class WordLengthTests(unittest.TestCase):
    def test_search_returns_minimum_cost_feasible_configuration_first(self) -> None:
        results = search_wordlengths(max_evm=0.03, widths=range(8, 17, 2), taps=8)
        feasible = [row for row in results if row["meets_constraint"]]
        self.assertTrue(feasible)
        self.assertTrue(results[0]["meets_constraint"])
        self.assertEqual(results[0]["cost_proxy"], min(row["cost_proxy"] for row in feasible))


if __name__ == "__main__":
    unittest.main()
