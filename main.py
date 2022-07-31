import argparse
import sys


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Wrapper script around any/all dotfile heavy lifting I don't want to do in bash."
    )
    parser.parse_args()
    return 0


if __name__ == '__main__':
    sys.exit(main())
