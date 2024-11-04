""" midas_to_phiat.py

    Part of PhIAT: Converting a MIDAS file to .csv format, and creating the Tacc_List sheet for PhIAT.m

    Language: Python 3

    Annabelle Czihaly (aczihaly@triumf.ca)
    University of Victoria
    TRIUMF, for the TITAN Collaboration
    
    v1.0 (9/11/2020) -- Initial script adapted from read_lmf_porter.py
    v1.1 (11/16/2020) -- Script changed to account for CAEN V1290 25ps TDC data
    v1.2 (1/12/2021) -- Script updated for VT2 TDC data
    v1.3 (7/26/2021) -- Script updated to account for empty files and test data from conditioning/calibrating PPG scheme
    
    Last updated on 7/26/2021
    
"""
from __future__ import division
import sys

sys.path.append('/Users/aczihaly/Documents/PIICR_Analysis/titan_data')
#sys.path.append('/Users/wsporter/Documents/Physics_Research/TITAN/PIICR_Analysis/titan_data') # Address of titan_data module. NEW USERS NEED TO CHANGE THIS! #

import struct
import time
import csv
import numpy as np
import pandas as pd
import glob
import re
import titan_data.mpet
import os # added

all_one_file = True # If TRUE, entire .mid becomes one .csv. If FALSE, each event becomes a separate .csv (If we want each event to be a different file, i.e. scanned over voltages between events, change to False)
CAEN = True # If True, output data files are only CAEN TDC data 
VT2 = False # If True, output data files are only VT2 TDC + LRS data
testing = True # If True, we're using test MIDAS files which include no reference files...this will automatically set the last file to have a Tacc of 0

if (VT2 and CAEN) == True:
    raise TypeError("Both VT2 and CAEN cannot be true, if you want both sets of data, please set both to False")

# NOTE: To test run this script alone: /path/to/directory/of/midas_to_phiat.py python3 midas_to_phiat.py /path/to/directory/of/files

file_dir = str(sys.argv[1])

#-------------added start-------------
#if only dealing with 1 file, glob doesn't need to sort (and won't work!). Created a function for dealing with 1 run
'''
lst = os.listdir(file_dir) #your directory path
number_files = len(lst) #get number of files
#print('there is/ are', number_files, 'file(s) in this directory') #sanity check

if number_files == 1: #if we only have 1 file, do this:
    filelist = glob.glob(file_dir + '/*.lz4') + glob.glob(file_dir + '/*.mid')

else: #if we have multiple runs, great! do this:
#the line below is the original code that wasn't in a function
    filelist = sorted(glob.glob(file_dir + '/*.lz4') + glob.glob(file_dir + '/*.mid')) # Grabbing all .mid AND .lz4 files in the directory of interest

#print('the list of files is', filelist) #sanity check
#-------------added end-------------
#the line below was original code, the block above was added 
'''
filelist = sorted(glob.glob(file_dir + '/*.lz4') + glob.glob(file_dir + '/*.mid')) # Grabbing all .mid AND .lz4 files in the directory of interest

#print(filelist)

time_list = []
ref_time_list = []
tacc_list = []
filename_list = []

test_stat = 0 # Used for testing, ensures one file is given a Tacc of 0 (i.e. becomes the necessary reference spot file for PI-ICR measurements)

for mfile in filelist:
    
    # Reading Data from MIDAS File #
    
    fileName = mfile
    mpet_file = titan_data.mpet.MPETFile(mfile)
    mpet_events = mpet_file.get_all_event_info()

    x_data = []
    y_data = []
    tof_data = []
    timestamp_data = []
    trigger_data = []
    event_UNIX = []
    
    caen_counter = 0
    caen_timestamp_counter = 0
    
    for mpet_event in mpet_events:
        
        # Data Structures for CAEN 25ps TDC #
        
        event_x_data_caen = []
        event_y_data_caen = []
        event_tof_data_caen = []
        event_timestamp_data_caen = []
        event_trigger_data_caen = []
        
        # Data Structures for LRS and VT2 TDC #
        
        event_x_data_vt2 = []
        event_y_data_vt2 = []
        event_tof_data_vt2 = []
        event_timestamp_data_vt2 = []
        event_trigger_data_vt2 = []
        
        # CAEN 25ps Data #
        
        caen_data = mpet_event.caen_tdc_parsed
        caen_data_raw = mpet_event.caen_tdc_raw
        
        for item in caen_data:
            # added start 
            for ch in item.all_tof_secs.keys():
                event_tof_data_caen.extend(t * 1e6 for t in item.all_tof_secs[ch]) #changed timestamp to tof
                #event_timestamp_data_caen.extend(t * 1e6 for t in item.all_tof_secs[ch])
                event_trigger_data_caen.extend([ch] * len(item.all_tof_secs[ch]))
                if len(item.pos_x_mm)>0:
                    event_x_data_caen.extend(item.pos_x_mm)
                    event_y_data_caen.extend(item.pos_y_mm)
                else:
                    event_x_data_caen.extend(([-1000] * len(item.all_tof_secs[ch])))
                    event_y_data_caen.extend(([-1000] * len(item.all_tof_secs[ch])))
            # added end
            # original code start
            ''' 
            for x_val in item.pos_x_mm: # Loop through ions per trigger
                event_x_data_caen.append(x_val) # X/Y Position from CAEN TDC
            for y_val in item.pos_y_mm:
                event_y_data_caen.append(y_val)
            for tof_val in item.mcp_tof_secs:
                event_tof_data_caen.append(tof_val) # ToF which ends at ion contact with MCP
                event_trigger_data_caen.append(item.trigger_count)
            ''' 
            # original code end
        
        """
        last_trig = None
        
        channel_list = []
        for tdc in caen_data_raw:
            if tdc.trigger_count != last_trig:
                channel_list = []
            last_trig = tdc.trigger_count
            channel_list.append(tdc.channel_id)
            print(channel_list)
            print(len(set(channel_list)))
            if len(set(channel_list)) == 5:
                event_timestamp_data_caen.append(tdc.timestamp_secs)
                event_trigger_data_caen.append(tdc.trigger_count)
                channel_list = []
                #break
        """    
        # VT2 TDC & LeCroy 1190 #
        
        pos_list = mpet_event.pos_data # X/Y Positions from LC1190
        for pos in pos_list:
            event_x_data_vt2.append(pos.x)
            event_y_data_vt2.append(pos.y)

        tdc_list = mpet_event.vt2_data # vt2_data corresponds to VT2 TDC // Change to tdc_data for VT4 TDC, as in titan_data
        for tdc in tdc_list:
            if tdc.channel_ids == [0]:
                event_tof_data_vt2.append(tdc.tof_secs) # ToF from trap ejection to initial MCP contact (1st ToF)
                event_timestamp_data_vt2.append(tdc.time_secs) # Timestamp corredsponding to initial MCP contact
        
        # Format/Organize Data #
        
        if CAEN == True:
            event_x_data = event_x_data_caen
            event_y_data = event_y_data_caen
            event_tof_data = event_tof_data_caen
            event_timestamp_data = event_timestamp_data_caen
            event_trigger_data = event_trigger_data_caen
        
        if VT2 == True:
            event_x_data = event_x_data_vt2
            event_y_data = event_y_data_vt2
            event_tof_data = event_tof_data_vt2
            event_timestamp_data = event_timestamp_data_vt2
            event_trigger_data = event_trigger_data_vt2
        
        else: # i.e. both VT2 and CAEN are False
            event_x_data = event_x_data_caen + event_x_data_vt2
            event_y_data = event_y_data_caen + event_y_data_vt2
            event_tof_data = event_tof_data_caen + event_tof_data_vt2
            event_timestamp_data = event_timestamp_data_caen + event_timestamp_data_vt2
            event_trigger_data = event_trigger_data_caen + event_trigger_data_vt2
        
        if all_one_file == True:
            for x in event_x_data:
                x_data.append(x)
            for y in event_y_data:
                y_data.append(y)
            for tof in event_tof_data:
                tof_data.append(tof)
            for timestamp in event_timestamp_data:
                timestamp_data.append(timestamp)
            for trigger in event_trigger_data:
                trigger_data.append(trigger)
        
        event_UNIX.append(mpet_event.event_time)
                
    x_data = np.array([x_data])
    y_data = np.array([y_data])
    tof_data = np.array([tof_data])
    trigger_data_array = np.array([trigger_data])
    
    #print('-------x_data---------',x_data)
    #print('-------y_data---------',y_data)
    #print('-------tof_data---------',tof_data)
    #print('-------trigger_data---------',trigger_data)
    
    if x_data.size == 0:
        print("The following file is empty:")
        print(fileName)
        raise TypeError('A file is empty! Please remove the empty file from the directory!')
    
    file_start = event_UNIX[0] # File start is timestamp of first event
    file_end = event_UNIX[-1] # File end is timestamp of last event
    #print(event_UNIX)
    
    # Constructing EventList #
    
    #print(x_data.T, y_data.T, tof_data.T) #added


    #eventList = np.concatenate((x_data.T,y_data.T,tof_data.T),axis=1)
    eventList = np.concatenate((x_data.T,y_data.T,tof_data.T,trigger_data_array.T),axis=1)
    
    #print(eventList)
    
    # Ion-Ion Interaction Cuts #
    
    if CAEN == True:
        ion_ion_cut_min = 100 # Max number of ions allowed in trap at a time, this can also change, orig = 5
        ion_ion_cut = 20 # Set some large max bound of possible ions in trap at once, orig = 20
        
        while ion_ion_cut >= ion_ion_cut_min:
            i = 0
            while i < len(eventList)-ion_ion_cut + 1:
                if (trigger_data[i+ion_ion_cut-1] - trigger_data[i] == 0):

                    indices = np.arange(i,i+ion_ion_cut+1) # added: create an array of indices to be deleted
                    eventList = np.delete(eventList, indices) #added 
                    #del eventList[i:i+ion_ion_cut] # If more than ion_ion_cut_min of ions are in one triggered set (i.e. in the trap together), cut the data out
                
                    i += ion_ion_cut
                else:
                    i += 1
            ion_ion_cut = ion_ion_cut - 1
    
    # Ion Rate #
    
    trap_time = mpet_event.trap_time_ms # Total time ions spend in trap
    
    if testing == True:
        trap_time = 100
        
    gating_rate = 50 # Bin size in time (ms) for ion counts
    
    num_eval = eventList[-1][3]*trap_time/gating_rate # Approx. global event time is (time in trap)*(trigger number)
    num_eval = int(num_eval)
    
    ion_rate = []
    
    for j in range(num_eval):
        k = 0
        num_counts = 0
        while k < len(eventList):
            if (eventList[k][3]*trap_time > j*gating_rate) and (eventList[k][3]*trap_time < (j+1)*gating_rate):  # If event time falls between bounds of our gate, add a count
                num_counts += 1
            k += 1
        
        ion_rate_ind = [(j+1)*gating_rate,num_counts,num_counts/gating_rate]
        ion_rate.append(ion_rate_ind)
    
    ## Ion Rate CSV Writing ##
    
    target_file = fileName + '_' + 'ion_rate.csv'
    with open(target_file,'w',newline='') as csvfile:
        datawriter = csv.writer(csvfile, delimiter=',')
        datawriter.writerows(ion_rate)
    
    ## Data CSV Writing ##
    
    target_file = fileName + '_' + '.csv'
    with open(target_file,'w',newline='') as csvfile:
        datawriter = csv.writer(csvfile, delimiter=',')
        datawriter.writerows(eventList)
    
    tacc = mpet_event.accumulation_time_ms
    
    if testing == True:
        test_stat += 1
        if test_stat == len(filelist):
            tacc = 0 # For testing: Will automatically make the last file have a Tacc of 0 to act as reference spot file
        
    if tacc == 0:
        ref_time_list.append(file_start + (file_end - file_start)/2)
    else:
        time_list.append(file_start + (file_end - file_start)/2)
    
    tacc_list.append(tacc) # Creating the column of Tacc and list of start times of each data file
    filename_list.append(target_file)

## File List Creator ##

mindex_list = []
for time in time_list:
    diff_list = []
    
    for ref_time in ref_time_list:
        diff = np.abs(ref_time - time)
        diff_list.append(diff)
    
    min_index = diff_list.index(min(diff_list)) # Finding the number of ref file closest in time to each actual file
    mindex_list.append(min_index+1)

for ref_time in ref_time_list:
    mindex_list.append('')

lists = [filename_list,tacc_list,mindex_list]
lists = zip(*lists) # Turning our data into a writable column-wise list

## CSV Writing of File List ##
target_file = file_dir + '_' + str(tacc_list[0]) + 'File_List' + '.csv'
with open(target_file,'w',newline='') as csvfile:
    datawriter = csv.writer(csvfile)
    datawriter.writerows(lists)

if __name__ == '__main__':
    
    sys.stdout.write(target_file) # Nothing else can be printed out for PhIAT.m to work properly