library(zoo)
library(corrplot)
library(foreach)
library(doMC)
registerDoMC()


                                        #v<-read.csv("out.csv", header=T)
v<-read.csv("out.csv", header=T)
topics <- read.csv("topicsummary.csv",header=T)

colors <- c(
            "#ff0000",
            "#ffbfbf",
            "#ff8000",
            "#ffff00",
            "#00ff00",
            "#00ffff",
            "#0000ff",
            "#8000ff",
            "#bf0080",
            "#40ffff",
            "#ffffff",
            "#bfbfbf",
            "#ffffbf",
            "#8000ff",
            "#800000",
            "#008080",
            "#bfffbf",
            "#bf4000",
            "#4080ff",
            "#bf8000"
            )

getTopic <- function(n) {
  paste(sapply(topics[n,], as.character),collapse=" ")
}
# 
# 
# plot(v$t1)
#  plot(v$t2)
#  plot(v$t3)
#  plot(v$t4)
#  plot(v$t5)
#  plot(v$t6)
# library(corrplot)
# names(v)
# nn <- names(v)[5:24]
# cor(v[,nn])
# corrplot(cor(v[,nn]))
# plot(v[,"t1"])
# > library(zoo)
# 
# rollmean(v$t1,50)
# plot(rollmean(v$t1,50))
# unique(v$authors)
# plot(rollmean(v$t8[v$author=="gbtami <devnull@localhost>"],50))
# plot(rollmean(v$t1[v$author=="gbtami <devnull@localhost>"],50))
# plot(rollmean(v$t2[v$author=="gbtami <devnull@localhost>"],50))
# plot(rollmean(v$t3[v$author=="gbtami <devnull@localhost>"],50))
# plot(rollmean(v$t4[v$author=="gbtami <devnull@localhost>"],50))
# corrgram(v[,nn], order=TRUE, row1attop=FALSE,
#          main="",
#          upper.panel=panel.ellipse,
#                  lower.panel=panel.pts,
#                  diag.panel=panel.minmax)
# 
# plot(v$t1)
# 
getday <- function(text) {
  strsplit(as.character(text),"T")[[1]][1]
}

vday <- sapply(v$time, getday)

avgperday <- function(v,vday,column, minreplace=0) {
  days <- unique(vday)
  x <- sapply(days, function(day) { mean(v[vday==day,column]) })
  x[!is.finite(x)] <- minreplace
  z <- c()
  z$days <- days
  z$x <- x
  z
}


polyplot <- function(l,xlabels=c(),
                     ourTitle = "title",
                     color = "aquamarine",
                     ylabel = "Avg. Commit Relevance",
                     xlabel = "Time",
                     borderColor = "black",
                     nlabels = 20) {
  below <- 1
  lx <- c(1:(length(l)))
  xx <- c(lx,rev(lx))
  ml <- min(l)
  maxl <- max(l)


  yy <- c(l, l*0+ml)


  plot(c(),xlim=c(1,length(l)),ylim=c(ml,maxl),xaxt="n",ylab=ylabel,xlab=xlabel,main=ourTitle)
  if (length(l) > nlabels) {
    n <- length(l)
    nlx <- round(lx*(n/nlabels))
    axis(below, nlx, xlabels[nlx])
  } else {
    axis(below, lx, xlabels)
  }
  #polygon(xx,yy,col="aquamarine",border="darkgreen",lty=2)
  polygon(xx,yy,col=color,border=borderColor,lty=1)  
}

unix2POSIXct  <-  function (time)   structure(time, class = c("POSIXt", "POSIXct"))

dateRange <- function(days) {
  days <- as.Date(days)
  as.Date(min(days):max(days))
}
everynth <- function(l , n) {
  l[1:length(l) %% n == 0]
}

plotatopic <- function(v, topic, n=14, f=mean) {
  title <- paste("Topic",topic,substr(getTopic(topic),0, 70),"...")
  vday <- sapply(v$time, getday)
  days <- dateRange( vday )
  ttopic = paste("t",topic,sep="")
  ldays <- everynth(dateRange(v$time),n)
  vd <- as.Date(v$time)
  vals <- sapply(ldays, function(day) { f(v[vd >= as.Date(day) & vd < as.Date(day)+n, ttopic]) })
  vals[!is.finite(vals)] = 0
  #l <- avgperday(v, days, ttopic, minreplace=min(v[,ttopic]))
  #if (length(l$x) < n) {
  #  print("Could Not Plot")
  #  return("Done")
  #}
  #vals <- rollmean(l$x,n,fill=min(l$x))
  #polyplot(vals, l$days, ourTitle = title, color=colors[topic])
  polyplot(vals, ldays, ourTitle = title, color=colors[topic])
  lines(lowess(vals))
}

uniqnum <- function(v,x) {
  c(1:length(v))[v == x]
}

strs <- c()
myauthors <- as.character(unique(v$author))
write.table(myauthors, file="out/author.table")
#for ( a in c(0,myauthors)) {
goodtopics <- c()
authorfunc <- function(a) {
  print(a)
  anum <- 0
  vv <- if (a != 0) { v[v$author==a,] } else { v }
  anum <- if (a != 0) { uniqnum(myauthors, a) } else { 0 }
  
  goodtopics <- c()
  for (topic in 1:20) {
    for (nsize in c(7)) {
      filenamepdf = paste(c("out/",anum,"-",topic,"-",nsize,".pdf"),sep="",collapse="")
      filenamepng = paste(c("out/",anum,"-",topic,"-",nsize,".png"),sep="",collapse="")
      print(filenamepdf)
      works <- F
      f <- function() {
        pdf(file=filenamepdf, width=12, height=5)
        plotatopic(vv,topic,n=nsize)
        dev.off()
        png(filenamepng, width=600, height=250, units = "px")
        plotatopic(vv,topic,n=nsize)
        dev.off()
        works <- T
        T
      }
      if (try(f())) {
        goodtopics <- c(goodtopics, topic)
      }
      try(dev.off())
    }
  }
  #goodtopics <- unique(goodtopics)
  print("goodtopics")
  print(goodtopics)
  blk <- function() {
    t1 <- sample(goodtopics,3)
    t2 <- sample(goodtopics,3)
    t3 <- sample(goodtopics,3)
    str1 <- paste(t1, collapse=",")
    str2 <- paste(t2, collapse=",")
    str3 <- paste(t3, collapse=",")
    uid <- anum
    user <- strsplit(a,"<")[[1]][1]
    userq <- paste("\"",user,"\"",sep="")
    surveyf <- function(topicstr) {
      outfile <- paste(c("out/survey-",uid,"-",topicstr,".odt"),sep="",collapse="")
      paste(c("perl","survey/gen-survey.pl"," -summary out/summary.txt",
              " -project $PROJECT -topics ", topicstr," -user",userq," -uid",uid,
              " -out ",outfile,"\n",
              "sh","survey/odt2pdf.sh",outfile
              )   ,sep=" ",collapse=" ")
    }
    newstr <- sapply(c(str1,str2,str3), surveyf)
    cat(newstr, file=paste("out/run-surveys-",anum,".sh",sep=""), sep="\n")
  }
  if (anum != 0) {
    try ( blk() )
  }
}

foreach ( a = c(0,myauthors)) %dopar% (authorfunc(a))


