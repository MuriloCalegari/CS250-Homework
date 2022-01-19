#!/usr/bin/python3

"""
Test kit for executable, SPIM, and Logisim files.
Uses provided settings file to test assignment.
"""

import argparse
from sys import stderr
from common import Grader

def main():
    """
    Parse arguments and run autograder.
    """
    parser = argparse.ArgumentParser(description="Run autograder.")
    parser.set_defaults()
    parser.add_argument("test_suite", type=str, choices=["ALL", "CLEAN", "mersenne", "recurse", "covidtracker"],
                        help="ALL, CLEAN, or test suite name", metavar="<suite>")
    parser.add_argument("--settings", type=str, default="settings.json",
                        help="settings file to use for grading (default=settings.json)")
    parser.add_argument('--make-expected', help=argparse.SUPPRESS, action='store_true') # not for student use! assumes program is correct and uses it to generate the expected outputs

    
    try:
        args = parser.parse_args()

        grader = Grader(args.test_suite, args.settings, args.make_expected)
        _ = grader.run()
        
    except:
        print("""
Auto Tester for Duke CS/ECE 250, Homework 1, Spring 2022

Usage:
  ./hw1test.py <suite>

Where <suite> is one of:
    ALL             : Run all program tests
    CLEAN           : Remove all the test output produced by this tool in tests/
    mersenne        : Run tests for mersenne
    recurse         : Run tests for recurse
    covidtracker    : Run tests for covidtracker
""", file=stderr, flush=True)
    

if __name__ == "__main__":
    main()
