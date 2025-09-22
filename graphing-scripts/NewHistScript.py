import os
import math
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import rcParams
rcParams['font.family'] = 'sans-serif'
rcParams['font.sans-serif'] = ['Arial']

figPath = 'C:\\Users\\hmgdt\\Desktop\\NSB-ABM\\caribou-Evolution-Hi Scenario\\Histogram Figures\\Hunters'
os.chdir(figPath)
directory = os.fsencode('C:\\Users\\hmgdt\\Desktop\\NSB-ABM\\KDE Data\\Hunters')

mat1 = np.loadtxt('C:\\Users\\hmgdt\\Desktop\\School\\Git\\NSB-ABM\\NDVI-HI Matrices\\GreenMatrix4.asc',skiprows = 6)
mat2 = np.loadtxt('C:\\Users\\hmgdt\\Desktop\\School\\Git\\NSB-ABM\\NDVI-HI Matrices\\GreenMatrix5.asc',skiprows = 6)
mat3 = np.loadtxt('C:\\Users\\hmgdt\\Desktop\\School\\Git\\NSB-ABM\\NDVI-HI Matrices\\GreenMatrix6.asc',skiprows = 6)
mat4 = np.loadtxt('C:\\Users\\hmgdt\\Desktop\\School\\Git\\NSB-ABM\\NDVI-HI Matrices\\GreenMatrix7.asc',skiprows = 6)
mat5 = np.loadtxt('C:\\Users\\hmgdt\\Desktop\\School\\Git\\NSB-ABM\\NDVI-HI Matrices\\GreenMatrix8.asc',skiprows = 6)
mat6 = np.loadtxt('C:\\Users\\hmgdt\\Desktop\\School\\Git\\NSB-ABM\\NDVI-HI Matrices\\GreenMatrix9.asc',skiprows = 6)
mat7 = np.loadtxt('C:\\Users\\hmgdt\\Desktop\\School\\Git\\NSB-ABM\\NDVI-HI Matrices\\GreenMatrix10.asc',skiprows = 6)
mat8 = np.loadtxt('C:\\Users\\hmgdt\\Desktop\\School\\Git\\NSB-ABM\\NDVI-HI Matrices\\GreenMatrix11.asc',skiprows = 6)
mat9 = np.loadtxt('C:\\Users\\hmgdt\\Desktop\\School\\Git\\NSB-ABM\\NDVI-HI Matrices\\GreenMatrix12.asc',skiprows = 6)
mat10 = np.loadtxt('C:\\Users\\hmgdt\\Desktop\\School\\Git\\NSB-ABM\\NDVI-HI Matrices\\GreenMatrix13.asc',skiprows = 6)

Elevation = np.genfromtxt('C:\\Users\\hmgdt\\Desktop\\NSB-ABM\\Scripts\\Elevation.txt')
Roughness = np.genfromtxt('C:\\Users\\hmgdt\\Desktop\\NSB-ABM\\Scripts\\Roughness.txt')
Wetness = np.genfromtxt('C:\\Users\\hmgdt\\Desktop\\NSB-ABM\\Scripts\\/Wetness.txt')

ndviC = []
elevationC = []
roughnessC = []
wetnessC = []

roughnessCHist = []
wetnessCHist = []
ndviCHist = []
edges = []

numBins = 25
subXLim = 25000
idx = 0
y = np.arange(numBins)

def normalize(arr):
    arr = arr.astype(float)
    arr_min = np.amin(arr)
    arr_max = np.amax(arr)
    arr_norm = (arr - arr_min) / (arr_max - arr_min)
    return arr_norm

def arrayNorm(arr):
    return [float(i)/sum(arr) for i in arr]

def bhattacharyya(a, b,dist):
    """ Bhattacharyya distance between distributions (lists of floats). """
    if not len(a) == len(b):
            raise ValueError("a and b must be of the same size")
    if dist == True:
        return -math.log(sum((math.sqrt(u * w) for u, w in zip(a, b))))
    else:
        return sum((math.sqrt(u * w) for u, w in zip(a, b)))

def makeNDVIHistArrays(fName,arr):
    scenData = np.genfromtxt(fName)
    scenData = np.transpose(scenData)
    scenData = np.delete(scenData,0,1)
    year = (scenData[0] >= (np.amax(scenData[0]) - 1440)) & (scenData[0] <= np.amax(scenData[0]))
    offset = np.amax(scenData[0]) - 1440
    ticks = scenData[0,:][year]
    xdat = scenData[2,:][year]
    ydat = scenData[3,:][year]
    for i in range(0, xdat.shape[0]):
        tick = ticks[i]
        x = xdat[i]
        y = ydat[i]
        x = int(x + 64)
        y = int(64 - y)
        if tick >= offset and tick < offset + 160:
            mat = mat1
        elif tick >= offset + 160 and tick < offset + 2 * 160:
            mat = mat2
        elif tick >= offset + 2 * 160 and tick < offset + 3 * 160:
            mat = mat3
        elif tick >= offset + 3 * 160 and tick < offset + 4 * 160:
            mat = mat4
        elif tick >= offset + 4 * 160 and tick < offset + 5 * 160:
            mat = mat5
        elif tick >= offset + 5 * 160 and tick < offset + 6 * 160:
            mat = mat6
        elif tick >= offset + 6 * 160 and tick < offset + 7 * 160:
            mat = mat7
        elif tick >= offset + 7 * 160 and tick < offset + 8 * 160:
            mat = mat8
        elif tick >= offset + 8 * 160 and tick < offset + 9 * 160:
            mat = mat9
        elif tick >= offset + 9 * 160 and tick < offset + 10 * 160:
            mat = mat10
        util = mat[x,y]
        arr.append(util)

    arr = np.asarray(arr)
    arr = normalize(arr)
    return arr

def makeHistArrays(fName, elevation, roughness, wetness):
    scenData = np.genfromtxt(fName)
    scenData = np.transpose(scenData)
    scenData = np.delete(scenData,0,1)
    year = (scenData[0] >= (np.amax(scenData[0]) - 1440)) & (scenData[0] <= np.amax(scenData[0]))
    xdat = scenData[2,:][year]
    ydat = scenData[3,:][year]
    for i in range(0, xdat.shape[0]):
        x = xdat[i]
        y = ydat[i]
        x = int(x + 64)
        y = int(64 - y)
        #print(x,y)
        elev = Elevation[y,x]
        rough = Roughness[y,x]
        wet = Wetness[y,x]
        elevation.append(elev)
        roughness.append(rough)
        wetness.append(wet)

    elevation = np.asarray(elevation)
    roughness = np.asarray(roughness)
    wetness = np.asarray(wetness)
    elevation = normalize(elevation)
    roughness = normalize(roughness)
    wetness = normalize(wetness)

    return (elevation,roughness, wetness)

"""
y = np.arange(numBins)
fig, axes = plt.subplots(ncols=3, sharey=True)
axes[0].barh(y, control, align='center', color='blue', zorder=10)
axes[0].set_title(controlTitle,fontsize = 13)
axes[0].set_xlabel(subx1,fontsize = 13)

axes[0].set(yticks= [0,5,10,15,20,25],yticklabels = [0.0,0.2,0.4,0.6,0.8])

plt.tick_params(labelcolor='none', top='off', bottom='off', left='off', right='off')
plt.grid(False)
if xlab == True:
    plt.xlabel('\nCount of Habitat Cell Utilization',fontsize = 13)
"""
for file in os.listdir(directory):
    fileName = os.fsdecode(file)
    fileNameGen = 'C:\\Users\\hmgdt\\Desktop\\NSB-ABM\\KDE Data\\Hunters\\' + fileName
    ndviC = []
    elevationC = []
    roughnessC = []
    wetnessC = []
    
    roughnessCHist = []
    wetnessCHist = []
    ndviCHist = []
    edges = []
    
    elevationC, roughnessC, wetnessC = makeHistArrays(fileNameGen,elevationC, roughnessC, wetnessC)
    ndviC = makeNDVIHistArrays(fileNameGen,ndviC)

    roughnessCHist, edges = np.histogram(roughnessC,numBins)
    wetnessCHist, edges = np.histogram(wetnessC,numBins)
    ndviCHist, edges = np.histogram(ndviC, numBins)

    fig, axes = plt.subplots(ncols=3, sharey=True)

    axes[0].barh(y,roughnessCHist,align = 'center',color = 'red', zorder=10)
    axes[0].set_title('Roughness',fontsize = 13)

    axes[1].barh(y,wetnessCHist,align = 'center',color = 'blue', zorder=10)
    axes[1].set_title('Wetness',fontsize = 13)

    axes[2].barh(y,ndviCHist,align = 'center',color = 'green', zorder=10)
    axes[2].set_title('NDVI',fontsize = 13)

    axes[0].set_xlim(0,subXLim)
    axes[1].set_xlim(0,subXLim)
    axes[2].set_xlim(0,subXLim)
    axes[0].set(yticks= [0,5,10,15,20,25],yticklabels = [0.0,0.2,0.4,0.6,0.8])
    axes[0].yaxis.tick_left()
    for ax in axes.flat:
        ax.margins(0.02)
        ax.grid(True)
    fig.set_figwidth(10)
    fig.subplots_adjust(wspace=0.2)
    fig.add_subplot(111, frameon=False)
    plt.tick_params(labelcolor='none', top='off', bottom='off', left='off', right='off')
    plt.grid(False)
    plt.xlabel('Count of Habitat Cell Utilization',fontsize = 13)
    plt.ylabel('Driver Layer Magnitude',fontsize = 13)
    fig.tight_layout()

    fileName = fileName[:-4]
    fileName += '-hunter-histograms.png'
    plt.savefig(fileName)
    plt.show()

"""
    elevationC.clear()
    roughnessC.clear()
    wetnessC.clear()
    ndviC.clear()
    roughnessCHist.clear()
    wetnessCHist.clear()
    ndviCHist.clear()
    edges.clear()
"""
