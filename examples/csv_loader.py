import IPython
import pandas as pd
import sys

df = pd.read_csv(sys.argv[1])
IPython.display.display(df)
IPython.embed(banner1='')
