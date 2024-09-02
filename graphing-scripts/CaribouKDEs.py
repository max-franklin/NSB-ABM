# -*- coding: utf-8 -*-


import os
import numpy as np
import matplotlib.pyplot as pl
import scipy.stats as st
from scipy.misc import imread
import matplotlib.cbook as cbook
from matplotlib_scalebar.scalebar import ScaleBar
figPath = 'C:\\Users\\hmgdt\\Desktop\\NSB-ABM\\Scenario KDE Figures\\Hunters'
datafile = cbook.get_sample_data('C:\\Users\\hmgdt\\Desktop\\NSB-ABM\\Scripts\\model.png')
img = imread(datafile)
#fileName = 'C:\\Users\\hmgdt\\Desktop\\NSB-ABM\\KDE Data\\0\\control-scenario-caribou-kde-data.txt'
os.chdir(figPath)
directory = os.fsencode('C:\\Users\\hmgdt\\Desktop\\NSB-ABM\\KDE Data\\Hunters')
idx = 0
nameCONST = 'hunters-'
nameTemp = nameCONST
#floors and ceilings: {2500,2550,7550,7600}
#months: june (0), july (1), august (2)

def buildKDE(month, floor, ceiling, dat, figname, index):
    #ticks = dat[0][month]
    #who = dat[1][month]
    xdat = dat[2][month]
    ydat = dat[3][month]

    #take a sample of the month data
    x = xdat[floor:ceiling]
    y = ydat[floor:ceiling]

    xmin, ymin = -64, -64
    xmax, ymax = 64, 64

    # Peform the kernel density estimate
    xx, yy = np.mgrid[xmin:xmax:256j, ymin:ymax:256j]
    positions = np.vstack([xx.ravel(), yy.ravel()])
    values = np.vstack([x, y])
    kernel = st.gaussian_kde(values, bw_method ='scott')#, bw_method=0.2)
    #kernel = st.gaussian_kde(values)
    f = np.reshape(kernel(positions).T, xx.shape)

    fmin = np.min(f)
    fmax = np.max(f)

    f = (f - fmin) / (fmax - fmin)

    fig = pl.figure()
    ax = fig.gca()
    ax.set_xlim(xmin, xmax)
    ax.set_ylim(ymin, ymax)
    #l = np.arange(0.2,1.2,0.2)
    l = [0.01, 0.25, 0.5,1.2]
    cfset = ax.contourf(xx, yy, f, levels = l, cmap='Greens', alpha = 0.6)
    ## Or kernel density estimate plot instead of the contourf plot
    #ax.imshow(np.rot90(f), cmap='Blues', extent=[xmin, xmax, ymin, ymax])

    #load image
    #datafile = cbook.get_sample_data('C:\\Users\\hmgdt\\Desktop\\NSB-ABM\\Scripts\\model.png')
    #img = imread(datafile)

    # Contour plot
    cset = ax.contour(xx, yy, f,levels = l, colors='k',zorder = 1)
    pl.imshow(img,zorder=0,extent=[xmin, xmax, ymin, ymax])
    # Label plot
    ax.clabel(cset, inline=1, fontsize=10)
    #ax.set_xlabel('Y1')
    #ax.set_ylabel('Y0')
    figname += '-' + str(index) + '.png'
    ax.set_axis_off()
    scalebar = ScaleBar(1100) # 1 pixel = 0.2 meter
    pl.gca().add_artist(scalebar)
    pl.savefig(figname)
    pl.show()
    #dat = None
#max_rows = 130000, skip_header = 1
#OR
#skip_header = 3380000

for file in os.listdir(directory):
    fileName = os.fsdecode(file)
    fileNameGen = 'C:\\Users\\hmgdt\\Desktop\\NSB-ABM\\KDE Data\\Caribou\\' + fileName
    fileName = fileName[:-4]
    npdat = np.genfromtxt(fileNameGen, max_rows = 130000, skip_header = 1)
    npdat = np.transpose(npdat)
    for i in range(0,3):
        #take month portion of the year's data
        month = (npdat[0] >= 0 + 480 * i) & (npdat[0] <= (0 + 480 * (i + 1)))
        nameTemp = nameCONST
        nameTemp += fileName + '-y0-early'
        buildKDE(month,2500,2550,npdat,nameTemp,i)
        nameTemp = nameCONST
        nameTemp += fileName + '-y0-late'
        buildKDE(month,7550,7600,npdat,nameTemp,i)
    npdat = None

    nameTemp = nameCONST
    npdat = np.genfromtxt(fileNameGen, skip_header = 3380000, max_rows = 300000)
    npdat = np.transpose(npdat)
    for i in range(0,3):
        month = (npdat[0] >= 169854 + 480 * i) & (npdat[0] <= (169854 + 480 * (i + 1)))
        nameTemp = nameCONST
        nameTemp += fileName + '-y100-early'
        buildKDE(month,2500,2550,npdat,nameTemp,i)
        nameTemp = nameCONST
        nameTemp += fileName + '-y100-late'
        buildKDE(month,7550,7600,npdat,nameTemp,i)
    npdat = None



















"""
ticks = npdat[0][month]
who = npdat[1][month]
xdat = npdat[2][month]
ydat = npdat[3][month]

#take a sample of the month data
#Early month
#x = xdat[2500:2550]
#y = ydat[2500:2550]
#Late month
#x = xdat[7550:7600]
#y = ydat[7550:7600]

xmin, ymin = -64, -64
xmax, ymax = 64, 64

# Peform the kernel density estimate
xx, yy = np.mgrid[xmin:xmax:256j, ymin:ymax:256j]
positions = np.vstack([xx.ravel(), yy.ravel()])
values = np.vstack([x, y])
kernel = st.gaussian_kde(values, bw_method ='scott')#, bw_method=0.2)
#kernel = st.gaussian_kde(values)
f = np.reshape(kernel(positions).T, xx.shape)

fmin = np.min(f)
fmax = np.max(f)

f = (f - fmin) / (fmax - fmin)


fig = pl.figure()
ax = fig.gca()
ax.set_xlim(xmin, xmax)
ax.set_ylim(ymin, ymax)
#l = np.arange(0.2,1.2,0.2)
l = [0.01, 0.25, 0.5,1.2]
cfset = ax.contourf(xx, yy, f, levels = l, cmap='Greens', alpha = 0.6)
## Or kernel density estimate plot instead of the contourf plot
#ax.imshow(np.rot90(f), cmap='Blues', extent=[xmin, xmax, ymin, ymax])
#load image
datafile = cbook.get_sample_data('C:\\Users\\hmgdt\\Desktop\\NSB-ABM\\Scripts\\model.png')
img = imread(datafile)
# Contour plot
cset = ax.contour(xx, yy, f,levels = l, colors='k',zorder = 1)
pl.imshow(img,zorder=0,extent=[xmin, xmax, ymin, ymax])
# Label plot
ax.clabel(cset, inline=1, fontsize=10)
#ax.set_xlabel('Y1')
#ax.set_ylabel('Y0')
ax.set_axis_off()
scalebar = ScaleBar(1100) # 1 pixel = 0.2 meter
pl.gca().add_artist(scalebar)
pl.savefig('control-late-aug-y100.png')
pl.show()
npdat = None
"""
