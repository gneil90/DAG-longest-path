# DAG-longest-path

In digital form the map looks like the number grid below.

4 4 

4 8 7 3 

2 5 9 3 

6 3 2 5 

4 4 1 6

The first line (4 4) indicates that this is a 4x4 map. 
Each number represents the elevation of that area of the mountain. 
From each area (i.e. box) in the grid you can go north, south, east, west - but only if the elevation of the area you are going into is
less than the one you are in.

You can start anywhere on the map and you are looking for a starting point with the longest possible path down as measured by the number
of boxes you visit. And if there are several paths down of the same length, you want to take the one with the steepest vertical drop, i.e
. the largest difference between your starting elevation and your ending elevation.

On this particular map the longest path down is of length=5 and it’s highlighted in bold below: 9-5-3-2-1.

This program finds the longest (and then steepest) path on this map specified in the format above. It’s 1000x1000 in size, and all the
numbers on it are between 0 and 1500.
