import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import re
from sklearn.linear_model import Ridge
from sklearn.model_selection import train_test_split,KFold
from sklearn import linear_model
from sklearn.metrics import mean_squared_error,r2_score
from pprint import pprint
from machineLearningProjectPlotter import *
from datetime import date,datetime
def predictPrecip():
    data = pd.read_csv('NYC_Bicycle_Counts_2016_Corrected.csv')
    data[['High Temp', 'Low Temp', 'Precipitation', 'Brooklyn Bridge', 'Manhattan Bridge', 'Williamsburg Bridge', 'Queensboro Bridge', 'Total']] = data[['High Temp', 'Low Temp', 'Precipitation', 'Brooklyn Bridge', 'Manhattan Bridge', 'Williamsburg Bridge', 'Queensboro Bridge', 'Total']].replace(r'T','0',regex=True)
    data[['High Temp', 'Low Temp', 'Precipitation', 'Brooklyn Bridge', 'Manhattan Bridge', 'Williamsburg Bridge', 'Queensboro Bridge', 'Total']] = data[['High Temp', 'Low Temp', 'Precipitation', 'Brooklyn Bridge', 'Manhattan Bridge', 'Williamsburg Bridge', 'Queensboro Bridge', 'Total']].replace(r'[, a-zA-Z)(]','',regex=True) 
    dates = data['Date'].copy()
    for i in range(len(data['Date'])):
        data['Date'][i] = datetime.strptime(data['Date'][i],'%d-%b')
        data['Date'][i].replace(year=2016)
        data['Date'][i] = data['Date'][i].toordinal()
    data['Day'] = data['Day'].replace(r'Sunday','0',regex=True)
    data['Day'] = data['Day'].replace(r'Monday','1',regex=True)
    data['Day'] = data['Day'].replace(r'Tuesday','1',regex=True)
    data['Day'] = data['Day'].replace(r'Wednesday','1',regex=True)
    data['Day'] = data['Day'].replace(r'Thursday','1',regex=True)
    data['Day'] = data['Day'].replace(r'Friday','1',regex=True)
    data['Day'] = data['Day'].replace(r'Saturday','0',regex=True)
    data = data.astype('float')
    avg_htemp = data['High Temp'].mean()
    sd_htemp = data['High Temp'].std()
    sd_ltemp = data['Low Temp'].std()
    avg_ltemp = data['Low Temp'].mean()
    yR = data['Precipitation'].copy()
    for i in range(len(yR)):
        if yR[i] > 0.0:
            yR[i] = 1
    X = data[['Total']] #[['Day','High Temp','Low Temp','Total']]
    y = data['Precipitation']
    X = X.to_numpy()
    #[X_train, X_test, y_train, y_test] = train_test_split(X, y, test_size=0.20, random_state=101)
    kf = KFold(5,shuffle=True)
    RMSEs = []
    R2s = []
    MODELs = []
    INTERCEPTs = []
    MEANs = []
    SDs = []
    for train_index, test_index in kf.split(X):
        X_train, X_test = X[train_index], X[test_index]
        y_train, y_test = y[train_index], y[test_index]
        #Normalizing training and testing data
        [X_train, trn_mean, trn_std] = normalize_train(X_train)
        MEANs.append(trn_mean)
        SDs.append(trn_std)
        X_test = normalize_test(X_test, trn_mean, trn_std)
        l=0
        model = train_model(X_train,y_train,l)
        rmse = error(X_test,y_test,model)
        yt = model.predict(X_test)
        r2 = r2_score(y_test,yt)
        RMSEs.append(rmse)
        R2s.append(r2)
        MODELs.append(model.coef_)
        INTERCEPTs.append(model.intercept_)
    (Xp,a,b) = normalize_train(X)
    MODELs = np.array(MODELs)
    RMSEs = np.array(RMSEs)
    R2s = np.array(R2s)
    INTERCEPTs = np.array(INTERCEPTs)
   # print(RMSEs.mean())
    print("average r2 for precipitation predictions")
    print(R2s.mean())
    #print(MODELs.mean(axis=0))
    #print(np.array(MEANs).mean(axis=0))
    fSum = 0
    for i in range(len(data['Total'])):
        fSum += (data['Total'][i] - data['Total'].mean())**2
    #print("Standard errpr")
    #print(RMSEs.mean()/fSum**.5)
    #print(np.array(SDs).mean(axis=0))
   # print(INTERCEPTs.mean())
    model.coef_ = MODELs.mean(axis=0) 
    model.intercept_ = INTERCEPTs.mean()
    yn = model.predict(Xp)
    r2 = r2_score(y,yn)
    print("aggregate r2")
    print(r2)
    plt.plot(dates,yn,label='p')
    plt.plot(dates,y,label = 'ac')
    results = [0] * len(yn)
    correct = 0
    for i in range(len(yn)):
        if yn[i] > 0:
            yn[i] = 1
        else:
            yn[i] = 0
        if y[i] >0:
            y[i] = 1
        else:
            y[i] = 0
        results[i] = yn[i] + y[i]
        if results[i] == 2 or results[i] == 0:
            correct +=1
    print("% correct")
    print(correct / len(yn) * 100)
    plt.legend()
    plt.show()
    plt.close()
    return model
    
def predictRiders():
    data = pd.read_csv('NYC_Bicycle_Counts_2016_Corrected.csv')
    data[['High Temp', 'Low Temp', 'Precipitation', 'Brooklyn Bridge', 'Manhattan Bridge', 'Williamsburg Bridge', 'Queensboro Bridge', 'Total']] = data[['High Temp', 'Low Temp', 'Precipitation', 'Brooklyn Bridge', 'Manhattan Bridge', 'Williamsburg Bridge', 'Queensboro Bridge', 'Total']].replace(r'T','0',regex=True)
    data[['High Temp', 'Low Temp', 'Precipitation', 'Brooklyn Bridge', 'Manhattan Bridge', 'Williamsburg Bridge', 'Queensboro Bridge', 'Total']] = data[['High Temp', 'Low Temp', 'Precipitation', 'Brooklyn Bridge', 'Manhattan Bridge', 'Williamsburg Bridge', 'Queensboro Bridge', 'Total']].replace(r'[, a-zA-Z)(]','',regex=True) 
    dates = data['Date'].copy()
    for i in range(len(data['Date'])):
        data['Date'][i] = datetime.strptime(data['Date'][i],'%d-%b')
        data['Date'][i].replace(year=2016)
        data['Date'][i] = data['Date'][i].toordinal()
    data['Day'] = data['Day'].replace(r'Sunday','0',regex=True)
    data['Day'] = data['Day'].replace(r'Monday','1',regex=True)
    data['Day'] = data['Day'].replace(r'Tuesday','1',regex=True)
    data['Day'] = data['Day'].replace(r'Wednesday','1',regex=True)
    data['Day'] = data['Day'].replace(r'Thursday','1',regex=True)
    data['Day'] = data['Day'].replace(r'Friday','1',regex=True)
    data['Day'] = data['Day'].replace(r'Saturday','0',regex=True)
    data = data.astype('float')
    avg_htemp = data['High Temp'].mean()
    sd_htemp = data['High Temp'].std()
    sd_ltemp = data['Low Temp'].std()
    avg_ltemp = data['Low Temp'].mean()
    for i in range(len(data['Precipitation'])):
        if data['Precipitation'][i] > 0.0:
            data['Precipitation'][i] = 1
    X = data[['Day','High Temp','Precipitation','Low Temp']]
    y = data['Total']
    X = X.to_numpy()
    kf = KFold(5,shuffle=True)
    RMSEs = []
    R2s = []
    MODELs = []
    INTERCEPTs = []
    for train_index, test_index in kf.split(X):
        X_train, X_test = X[train_index], X[test_index]
        y_train, y_test = y[train_index], y[test_index] 
        #Normalizing training and testing data
        [X_train, trn_mean, trn_std] = normalize_train(X_train)
        X_test = normalize_test(X_test, trn_mean, trn_std)
        l= 0 
        model = train_model(X_train,y_train,l)
        rmse = error(X_test,y_test,model)
        yt = model.predict(X_test)
        (Xp,a,b) = normalize_train(X)
        r2 = r2_score(y_test,yt)
        RMSEs.append(rmse)
        R2s.append(r2)
        MODELs.append(model.coef_)
        INTERCEPTs.append(model.intercept_)
    MODELs = np.array(MODELs)
    RMSEs = np.array(RMSEs)
    R2s = np.array(R2s)
    INTERCEPTs = np.array(INTERCEPTs)
    #print(RMSEs.mean())
    print("average r2")
    print(R2s.mean())
    #print(MODELs.mean(axis=0))
    #print(INTERCEPTs.mean())
    model.coef_ = MODELs.mean(axis=0) 
    model.intercept_ = INTERCEPTs.mean()
    yn = model.predict(Xp)
    r2 = r2_score(y,yn)
    print("aggregated model r2")
    print(r2)
    plt.plot(dates,yn,label='p')
    plt.plot(dates,y,label = 'ac')
    plt.legend()
    plt.show(block=False)
    plt.close()
    return model

def which():
    data = pd.read_csv('NYC_Bicycle_Counts_2016_Corrected.csv')
    data[['High Temp', 'Low Temp', 'Precipitation', 'Brooklyn Bridge', 'Manhattan Bridge', 'Williamsburg Bridge', 'Queensboro Bridge', 'Total']] = data[['High Temp', 'Low Temp', 'Precipitation', 'Brooklyn Bridge', 'Manhattan Bridge', 'Williamsburg Bridge', 'Queensboro Bridge', 'Total']].replace(r'T','0',regex=True)
    data[['High Temp', 'Low Temp', 'Precipitation', 'Brooklyn Bridge', 'Manhattan Bridge', 'Williamsburg Bridge', 'Queensboro Bridge', 'Total']] = data[['High Temp', 'Low Temp', 'Precipitation', 'Brooklyn Bridge', 'Manhattan Bridge', 'Williamsburg Bridge', 'Queensboro Bridge', 'Total']].replace(r'[, a-zA-Z)(]','',regex=True) 
    dates = data['Date'].copy()
    X = data.columns
    label = 0
    for x in range(2,len(X)):
        data[X[x]] = data[X[x]].astype('float')
    XNoW = data[['Manhattan Bridge','Queensboro Bridge','Brooklyn Bridge']]
    XNoB = data[['Manhattan Bridge','Queensboro Bridge','Williamsburg Bridge']]
    XNoQ = data[['Manhattan Bridge','Brooklyn Bridge','Williamsburg Bridge']]
    XNoM = data[['Queensboro Bridge','Brooklyn Bridge','Williamsburg Bridge']]
    #best truple is brooklyn,manhattan,williamsburg
    y = data[['Total']]
    datasets = [XNoW,XNoB,XNoQ,XNoM]
    for X in datasets:
        X = X.to_numpy()
        [X_train, X_test, y_train, y_test] = train_test_split(X, y, test_size=0.25, random_state=101)
        #Normalizing training and testing data
        [X_train, trn_mean, trn_std] = normalize_train(X_train)
        X_test = normalize_test(X_test, trn_mean, trn_std)
        l= 0 
        model = train_model(X_train,y_train,l)
        rmse = error(X_test,y_test,model)
        #Store the model and mse in lists for further processing
        (Xp,a,b) = normalize_train(X)
        print("rmse for group: " + str(label))
        print(rmse)
        yn = model.predict(Xp)
        plt.plot(dates,yn,label=str(label))
        label += 1 
    plt.plot(dates,y,label = 'ac')
    plt.legend()
    plt.show(block=False)
    plt.close()
    return model

def normalize_train(X_train):
    mean = []
    std = []
    mean = X_train.mean(axis=0,dtype='float64')
    std = X_train.std(axis=0,dtype='float64')
    X = X_train
    #X.astype(float)
    #print(X_train.shape)
    #print(X.shape)
    for i,r in enumerate(X_train):
        for j,c in enumerate(r):
            X[i][j] = (X_train[i][j] - mean[j]) / std[j]
            #print("X_train[i][j]", X_train[i][j])
            #print("mean[j]", mean[j])
            #print("std[j]", std[j])
            #print("X",X[i][j])
    #fill in
    return X, mean, std


#Function that normalizes testing set according to mean and std of training set
#Input: testing data: X_test, mean of each column in training set: trn_mean, standard deviation of each
#column in training set: trn_std
#Output: X, the normalized version of the feature matrix, X_test.
def normalize_test(X_test, trn_mean, trn_std):
    #fill in
    X=X_test
    for i,r in enumerate(X_test):
        for j,c in enumerate(r):
            X[i][j] = (X_test[i][j] - trn_mean[j]) / trn_std[j]
    return X



#Function that trains a ridge regression model on the input dataset with lambda=l.
#Input: Feature matrix X, target variable vector y, regularization parameter l.
#Output: model, a numpy object containing the trained model.
def train_model(X,y,l):
    #fill in
    model = Ridge(alpha = l, fit_intercept=True)
    model.fit(X,y)
    return model


#Function that calculates the mean squared error of the model on the input dataset.
#Input: Feature matrix X, target variable vector y, numpy model object
#Output: mse, the mean squared error
def error(X,y,model):
    yn = model.predict(X)
    rmse = mean_squared_error(y,yn)**.5    #Fill in
    return rmse

if __name__ == '__main__':
    model = predictPrecip()
    model = predictRiders()
    model = which()
    #print("coefficients")
    #pprint(model.coef_)
    #print("intercept ")
    #pprint(model.intercept_)
