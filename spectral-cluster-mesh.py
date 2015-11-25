#!/bin/usr/env python

# it's easy bro

from sklearn.cluster import spectral_clustering
labels = spectral_clustering(adjmat, n_clusters=n_clusters, assign_labels='discretize')


