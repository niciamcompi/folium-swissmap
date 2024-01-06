# Data Import and Visualization
# Import necessary packages
import pyreadstat
import pandas as pd
import geopandas as gpd
import networkx as nx
import matplotlib.pyplot as plt
import folium
from keplergl import KeplerGl
import descartes
from pyproj import Proj, transform
from functools import partial
from shapely.geometry import Polygon
import shapely

# Load GeoDataFrame and filter relevant data
# Visualize the first few rows of the GeoDataFrame
gemeinde = gpd.read_file(r"~/Gemeinden.shp")
newdf = gemeinde.query('OBJEKTART == "Gemeindegebiet"')
print(gemeinde.head())

# Transform GeoDataFrame to WGS84 coordinate reference system
nc_counties = newdf.to_crs("epsg:4326")

# Read and preprocess csv datasets
df1 = pd.read_csv(r'~/faux.csv')
df2 = pd.read_csv(r'~/bfsnummern.csv')

# Filter and transform relevant variables
df2 = df2[["PLZ", "WOBFS", "Region"]]
df1['zip'] = df1['zip'].astype("Int64")

# Merge datasets and handle duplicates
merged = pd.merge(df1, df2, left_on='zip', right_on='PLZ', how='inner')
merged = merged.drop_duplicates(subset=['MACH_ID'])

# Group by postal code and BFS number, then merge with GeoDataFrame
merged2 = merged.groupby(['PLZ', 'WOBFS']).size().reset_index(name='counts')
merged_map = pd.merge(nc_counties, merged2, left_on='BFS_NUMMER', right_on='WOBFS', how='left')

# Aggregate counts for each area
interarea = merged_map.groupby(['NAME'])['counts'].sum().reset_index(name='Anzahl')

# Merge with GeoDataFrame and handle missing values
dfgreen = merged_map.merge(right=interarea, how='inner', left_on="NAME", right_on="NAME")
dfgreen = dfgreen.fillna(0)

# Create choropleth map using KeplerGl
m = dfgreen.explore(
    column="Anzahl",          # Choropleth based on "Anzahl" column
    tooltip=["NAME", "PLZ", "Anzahl"],  # Show information on hover
    popup=True,               # Show all values on click
    tiles="CartoDB positron", # Use "CartoDB positron" tiles
    cmap="Set1",              # Use "Set1" matplotlib colormap
    style_kwds=dict(color="black"),  # Use black outline
)

# Save the map as an HTML file
m.save('~/swissmap.html')
