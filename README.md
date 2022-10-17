# Sketchup-Lidar-LAS-LAZ-Importer

### STEP 1

Merge multiple LAZ and LAS files into a single LAS file the will be imported into Skecthup. 

Merge Usage:

Extensions > Merge LAZ/LAS Files

![Extensions](https://user-images.githubusercontent.com/88683212/196270410-9d5f3d28-2410-4bf1-bd4a-c34350eebe2c.png)


Select one or more files that will be merged and converted into the LAS file format

![selectfiles](https://user-images.githubusercontent.com/88683212/196270599-dc99051e-4b9f-4862-a9c9-e7b1f5d4931e.png)


Select the Grid spacing to sub-sample the input files and Click Merge. The output file name will be displayed in the 'Results:' area after the merge has completed.

![mergeoptions](https://user-images.githubusercontent.com/88683212/196270775-81165f53-454a-41c4-8418-5df7f20e841d.png)



### STEP 2

Importer Usage:

File > Menu > Import
Select Lidar las Importer *.las

Select Options...
In the Options dialog choose the Point Classifications, and Horizontal and Vertical units. Click OK

Click Import.

![options1](https://user-images.githubusercontent.com/88683212/136084172-1bb84b37-641b-45fa-88e8-62b19ead15fd.jpg)

The Import Type dialog will pop up giving you the choice to import the points as a Surface or as Construction Points, the amount to 'thin' the datapoints, and a toggle-able array of subregions to import.

![563x578](https://user-images.githubusercontent.com/88683212/161572288-484b1daf-66da-4da2-b064-3358b7fde970.jpg)





Wait for the points to import.

![progress](https://user-images.githubusercontent.com/88683212/136086209-8c2231e6-04f3-402c-80d9-03b62a407359.png)

The result will be a Sketchup Group containing the Lidar Data

![terrain](https://user-images.githubusercontent.com/88683212/136083260-4c448c8d-e9ee-40b9-9f27-cacfe13d88dd.jpg)

### Note:  Depending on your version of Sketchup, you should probably use datasets with less than 50,000 points and/or 100,000 faces. Larger quantites may strain your patience.



