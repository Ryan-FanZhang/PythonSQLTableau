#!/usr/bin/env python
# coding: utf-8

# In[1]:


# this is a dataset of user behaviours of Alibaba, there are some interesting results I would like to extract from this dataset.


# In[2]:


# import the packages 

import pandas as pd 


# In[3]:


# data processed 
DATA_PATH = 'E:\data for traning/UserBehavior.csv'
# the lines of this dataset is more than 1 billion, so we just have a look at the 1 million lines of data
df = pd.read_csv(DATA_PATH, nrows=1000000)


# In[4]:


df


# In[5]:


# we could see this one does not have the column name, so we will rename the columns
df.columns = ['user_id','item_id','cate_id','behavior_type','timestamp']


# In[8]:


# double check the columns 
df


# In[12]:


# import to MySQL to do futher process
df.to_csv('E:\\data for traning\\alibaba/ubhsmall.csv')


# In[ ]:




