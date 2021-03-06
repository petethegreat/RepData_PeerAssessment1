---
title: "Reproducible Research: Peer Assessment 1"
output: 
  html_document:
    keep_md: true
---
Reproducible Research assignment 1: Daily activity monitoring
==============================================================

Note: Rstudio is being funny. Using the following to knit HTML from the .Rmd

```
library(knitr)
library(markdown)
knit('PA1_template.Rmd')
markdownToHTML('PA1_template.md','PA1_template.html')
```

## Loading and preprocessing the data
load the data here. Load the data from the csv as "data", casting the "date" field as a date class. Also load ggplot2 and dplyr while we're at it.

```r
data<-read.csv('activity.csv')
data$date <- as.Date(data$date)
data$weekday <- weekdays(data$date)

suppressMessages(library(ggplot2))
```

```
## Warning: package 'ggplot2' was built under R version 3.1.3
```

```r
suppressMessages(library(dplyr))
```

```
## Warning: package 'dplyr' was built under R version 3.1.3
```
## What is mean total number of steps taken per day?

1. Make a histogram of the total number of steps taken each day

Use the ``aggregate`` function to compute total steps per day, then plot steps taken per day as a histogram. This uses the ggplot2 package.

```r
stepsPerDay<-aggregate(steps~date,data,sum)
g<-ggplot(data=stepsPerDay,aes(steps,fill=..count..),na.rm=TRUE) 
labels<- labs(x='steps per day')
g+  geom_histogram(binwidth=1000) + labels
```

![plot of chunk unnamed-chunk-2](figure/unnamed-chunk-2-1.png)

2. Calculate and report the **mean** and **median** total number of steps taken per day

Get the mean and median steps per day using the mean and median functions on the stepsPerDay dataframe.


```r
themean=mean(stepsPerDay$steps)
themedian=median(stepsPerDay$steps)
```

```r
themean
```

```
## [1] 10766.19
```

```r
themedian
```

```
## [1] 10765
```
That's pretty good. My phone says I did 65k steps last week.

## What is the average daily activity pattern?

1. Make a time series plot (i.e. `type = "l"`) of the 5-minute interval (x-axis) and the average number of steps taken, averaged across all days (y-axis)

Want to plot steps per 5-min interval, averaged over all days
Use the ```aggregate``` function to get this data.

```r
stepsPerInterval<-aggregate(steps~interval,data,mean)
g<-ggplot(data=stepsPerInterval,aes(interval,steps,colour='red')) 
labels<- labs(x='interval',y='mean steps per 5 minute interval')
g+  geom_line() + labels
```

![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6-1.png)

2. Which 5-minute interval, on average across all the days in the dataset, contains the maximum number of steps?
Max would give us the maximum value of steps. Use ```which.max()``` to get the row that contains the maximum.

```r
stepsPerInterval[which.max(stepsPerInterval$steps),]
```

```
##     interval    steps
## 104      835 206.1698
```
interval 835 (206 steps). Presumably this is 8.35-8.40 am? Subject could be walking to work.


## Imputing missing values

1. Calculate and report the total number of missing values in the dataset (i.e. the total number of rows with `NA`s)

How many missing values are there?

```r
dim(data)
```

```
## [1] 17568     4
```

```r
sum(is.na(data$steps))
```

```
## [1] 2304
```
Quite a bit. How are the missing values distributed by day? Group steps by day, sum the NA values for each group.

```r
missByDay<- data %>% select(date,steps) %>% group_by(date) %>% summarise_each(funs(sum(is.na(.))),missing=steps)
missByDay %>% filter(missing > 0)
```

```
## Source: local data frame [8 x 2]
## 
##         date missing
##       (date)   (int)
## 1 2012-10-01     288
## 2 2012-10-08     288
## 3 2012-11-01     288
## 4 2012-11-04     288
## 5 2012-11-09     288
## 6 2012-11-10     288
## 7 2012-11-14     288
## 8 2012-11-30     288
```
So for each of these 8 days, the steps data for every interval is missing. That makes life easier, as we're not sampling some intervals more often than others.

#### Impute things. 
2. Devise a strategy for filling in all of the missing values in the dataset. The strategy does not need to be sophisticated. For example, you could use the mean/median for that day, or the mean for that 5-minute interval, etc.
3. Create a new dataset that is equal to the original dataset but with the missing data filled in.



Compute the mean and median steps grouped by weekday and interval, with missing values omitted. Store this information in a dataFrame called lookup, as it will be used as a lookup table for the imputation.


```r
data$weekday = weekdays(data$date)
lookup<- data %>% select(steps,weekday,interval) %>% group_by(weekday,interval) %>%
 summarize_each(funs(meansteps=mean(.,na.rm=TRUE),medsteps=median(.,na.rm=TRUE)))
```

Impute the missing values. First copy data as impData. Left join impData with lookup, based on weekday and interval. This will add the meansteps and medsteps columns from lookup to impData, based on when the weekday and interval columns match. Left join is good, as rows will not be deleted from impData if there is no match in lookup (even though this shouldn't occur). Now every row in impData has mean and median step data. For rows in which steps is missing (```is.na()```), copy meansteps to steps. Finally, delete the meansteps and mediansteps columns from impData. Note that as the mean is not an integer, some rows in steps will have non-integer values after imputation. Not a big deal.

(This question on [stackoverflow](http://stackoverflow.com/questions/35670213/replace-values-in-some-rows-based-on-other-dataframe-mapping-with-r) was helpful).


```r
thecolumn<-"meansteps"
impData<-data
impData <- impData  %>% left_join( select(lookup,c(interval,weekday,meansteps,medsteps)),by=c("weekday"="weekday","interval"="interval"))
impData[is.na(impData$steps),"steps"]<-impData[is.na(impData$steps),thecolumn]
impData <- impData %>% select(date,interval,weekday,steps)
```
#### Plot the imputed data.

4. Make a histogram of the total number of steps taken each day and Calculate and report the **mean** and **median** total number of steps taken per day. Do these values differ from the estimates from the first part of the assignment? What is the impact of imputing missing data on the estimates of the total daily number of steps?

Make a histogram of total steps, same as for part 1 above, but using the imputed data.

```r
stepsPerDayi<-aggregate(steps~date,impData,sum)
g<-ggplot(data=stepsPerDayi,aes(steps,fill=..count..),na.rm=TRUE) 
labels<- labs(x='steps per day',title='imputed data')
g+  geom_histogram(binwidth=1000) + labels
```

![plot of chunk unnamed-chunk-12](figure/unnamed-chunk-12-1.png)

Compute the mean and median daily steps after imputation.


```r
mean(stepsPerDayi$steps)
```

```
## [1] 10821.21
```

```r
median(stepsPerDayi$steps)
```

```
## [1] 11015
```
These are a little different(slightly higher), but not much. We are looking at the mean steps per day, whereas we imputed by mean steps per interval/weekday, so should not expect the mean to remain unchanged (or the median, for that matter).

## Are there differences in activity patterns between weekdays and weekends?

1. Create a new factor variable in the dataset with two levels -- "weekday" and "weekend" indicating whether a given date is a weekday or weekend day.


```r
impData$weekend<- factor(impData$weekday %in% c('Saturday','Sunday'),labels=c('Weekday','Weekend'))
```
2. Make a panel plot containing a time series plot (i.e. `type = "l"`) of the 5-minute interval (x-axis) and the average number of steps taken, averaged across all weekday days or weekend days (y-axis). 



```r
impStepsPerInterval<-aggregate(steps~interval+weekend,data=impData,mean)
g<- ggplot(data=impStepsPerInterval,aes(x=interval,y=steps,colour='red'))

labels<-labs(x="interval",y="mean steps per interval")
title<- ggtitle("Mean Steps per 5 Minute Interval, for Weekdays and Weekends")

g+ geom_line() + facet_grid(.~weekend) +
	labels + title
```

![plot of chunk unnamed-chunk-15](figure/unnamed-chunk-15-1.png)

Yup, there are differences. Subject tends to be more active earlier in the day during the week, and more active later in the day during the weekend.

I also like this plot


```r
# I also like this plot
h<- ggplot(data=impStepsPerInterval,aes(x=interval,y=steps,colour=steps))
h + geom_point() + facet_grid(.~weekend) +
	scale_colour_gradientn(colours=c('purple','red')) +
	geom_smooth() + labels + title
```

![plot of chunk unnamed-chunk-16](figure/unnamed-chunk-16-1.png)




