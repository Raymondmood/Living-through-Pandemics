Please note that the 4 files detailed below remain the property of Raymond Moodley, Fabio Caraffini, Francisco Chiclana, and Mario Gongora.
These files are used to help organisations with the management of pandemics / epidemics.
Using these for any purpose other than its intention or for financial gain is strictly prohibited without the consent of the owners. Please email raymond.moodley@dmu.ac.uk if you have any queries.
The data fields in the input file Dataset_1 are obtained from publicly available sources, including Office of National Statistics, UK, UK Parliament, and UK Department for Education


The file details are as follows:

1. Dataset_1 (input file for SOM_Model-with-GB-map)
Fields:
Index - row number
Region - region in the UK
Code - parliamentary constituency code as used by Office of National Statistics (ONS) and UK Parliament
Child, Adult, Over 60s, Total People - data is obtained from UK Parliament website - see constituency dashboard
Vulnerability - it is the ratio of over 60s to total population
Commute - the nett jobs available in a constituency - nett jobs done by constituents - taken from ONS
School mobility - ratio of out of local area movement of primary school children - taken from ONS, Department for Education - Scotland and Wales assumed at 0.01 and 0.013 respectively. Some data points spans across multiple constituencies - all consituencies for that data point are given the same value. 
Population Density - data is obtained from UK Parliament website - see constituency dashboard
People per House - data obtained from ONS website and UK Parliament (total population divided by number of houses)
Economic Output - GVA taken from ONS website - provided by region which encompasses multiple constituencies - divided equally amongst constituencies.

2. party_colour
This is the HEX_CODE colour coding (based on terrain colour palette) for R

3. SIR_model-SIMULATOR
Program to simulate SIR

4. SOM_model_with-GB-map
Program to create SOM 
  