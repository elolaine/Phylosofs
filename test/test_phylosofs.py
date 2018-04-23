import phylosofs
import unittest
import subprocess
import filecmp
import os
import itertools


def compare_files(fpath1, fpath2):
    """
    Compare two files without taking into account newline characters.

    It allows to compare files generated by linux and windows.
    Code from: 
    https://stackoverflow.com/questions/40751389/compare-2-files-line-by-line-ignoring-newline-differences
    """
    with open(fpath1, 'r') as file1, open(fpath2, 'r') as file2:
        for linef1, linef2 in itertools.izip(file1, file2):
            linef1 = linef1.rstrip('\r\n')
            linef2 = linef2.rstrip('\r\n')
            if linef1 != linef2:
                return False
        return next(file1, None) is None and next(file2, None) is None


def path_tmp(filename):
    "Return the path to test/tmp/filename using os.path.join()."
    return os.path.join("test", "tmp", filename)


def path_dat(filename):
    "Return the path to test/data/filename using os.path.join()."
    return os.path.join("test", "data", filename)

         
PATH_TMP = os.path.join("test", "tmp")
PATH_PHYLOSOFS = os.path.join("phylosofs", "phylosofs.py")

if not os.path.isdir(PATH_TMP):
    os.mkdir(PATH_TMP)


class Test_PhyloSofS(unittest.TestCase):

    def test_phylosofs(self):
        path_data = os.path.join("dat", "JNK3.txt")
        command = ["python", PATH_PHYLOSOFS,
                   "-P",
                   "-o", PATH_TMP,
                   "--inseq", path_data]
        self.assertEqual(subprocess.call(command), 0)
        self.assertTrue(compare_files(path_tmp('treeSearch_532_1.txt'), 
                                      path_dat('treeSearch_532_1.txt')))
        self.assertTrue(compare_files(path_tmp('solution_532_1_config0.sum'),
                                      path_dat('solution_532_1_config0.sum')))
        self.assertTrue(compare_files(path_tmp('solution_532_1_config0.info'),
                                      path_dat('solution_532_1_config0.info')))
        self.assertFalse(os.path.isdir(os.path.join("test", "tmp",
                                                    "bestTopos")))
        self.assertFalse(os.path.isdir(os.path.join("test", "tmp",
                                                    "betterTrees")))

    def test_best_topos_and_trees(self):
        path_data = os.path.join("dat", "JNK3.txt")
        command = ["python", PATH_PHYLOSOFS,
                   "-P",
                   "-o", PATH_TMP,
                   "-s", "100",
                   "--inseq", path_data]
        self.assertEqual(subprocess.call(command), 0)
        self.assertTrue(os.path.isdir(os.path.join("test", "tmp",
                                                   "bestTopos")))
        self.assertTrue(os.path.isdir(os.path.join("test", "tmp",
                                                   "betterTrees")))
        self.assertGreater(len(os.listdir(os.path.join("test", "tmp",
                                                       "bestTopos"))), 0)
        self.assertGreater(len(os.listdir(os.path.join("test", "tmp",
                                                       "betterTrees"))), 0)

    def tearDown(self):
        phylosofs.utils.clear_folder(PATH_TMP)


if __name__ == '__main__':
    unittest.main()
