get_readscount<-function(IP_BAM,Input_BAM,contrast_IP_BAM,contrast_Input_BAM,GENE_ANNO_GTF=NA, GENOME = NA,UCSC_TABLE_NAME = "knownGene",TXDB = NA,sample_size=NA)
{
  
  # download the annotation
  if ( suppressWarnings((!is.na(GENOME)) & (!is.na(UCSC_TABLE_NAME))& is.na(TXDB)&is.na(GENE_ANNO_GTF))) {
    op <- options(warn = (-1))
    txdb =makeTxDbFromUCSC(genome=GENOME,
                           tablename=UCSC_TABLE_NAME)
    options(op)
  }
  if (suppressWarnings(!is.na(GENE_ANNO_GTF) & is.na(TXDB)) ) {
    op <- options(warn = (-1))
    txdb<-makeTxDbFromGFF(GENE_ANNO_GTF,format="gtf")
    options(op)
  }
  
  # use provided annotation data file
  if ( suppressWarnings(!is.na(TXDB)) ) {
    txdb<-loadDb(TXDB)
  }
  gc <- makeGuitarCoordsFromTxDb(txdb,noBins = 20) 
  gc_info <- mcols(gc)
  if((length( contrast_IP_BAM)!=0)&((length(contrast_Input_BAM)!=0)))
  {
    index <-c(IP_BAM, Input_BAM,contrast_IP_BAM,contrast_Input_BAM)
    index<-as.character(index)
  }
  if((length(contrast_IP_BAM)==0)&length(contrast_Input_BAM)==0)
  {
    index <-c(IP_BAM, Input_BAM)
    index<-as.character(index)
  }
  file <-index
  sample_name<-.get.sampleid(IP_BAM, Input_BAM,contrast_IP_BAM,contrast_Input_BAM)
  sample_name<-unlist(sample_name)
  sample_name<-as.vector(sample_name)
  transform_table<-cbind(file,sample_name)
  transform_table<-as.data.frame(transform_table)
  # get reads count
  result2<- gc_info
  noFiles <- length(file)
  total_reads <- vector()
  exon_reads <- vector()
  intron_reads <- vector()
  percent_intron <- vector()
  UTR5_reads <- vector()
  CDS_reads <- vector()
  UTR3_reads <- vector()
  percent_UTR5 <- vector()
  percent_CDS <- vector()
  percent_UTR3 <- vector()
  if(is.na(sample_size))
  {
    for (i in 1:noFiles) {
      print(paste("working on the ",i,"-th bam file ...",sep=""))
      bam <- readGAlignments(file[i])
      total_reads[i] <- paste(round(length(bam)/10^7,2), "M")
      bin_count <- countOverlaps(gc,bam)
      bin_count <- data.frame(bin_count)
      names(bin_count) <- sample_name[i]
      result2 <- data.frame(result2,bin_count)
      exon <- exonsBy(txdb, by = "tx")
      exon_count <- countOverlaps(bam,exon)
      exon_reads[i] <- paste(round(sum(exon_count>0)/10^7, 2), "M")
      intron <- intronsByTranscript(txdb)
      intron_count <- countOverlaps(bam,intron)
      intron_reads[i] <- paste(round(sum(intron_count>0)/10^7, 2), "M")
      percent_intron[i] <- paste(round((sum(intron_count>0)/(sum(intron_count>0)+sum(exon_count>0)))*100,2), "%")
      utr5 <- fiveUTRsByTranscript(txdb)
      utr5_count <- countOverlaps(bam,utr5)
      UTR5_reads[i] <- paste(round(sum(utr5_count>0)/10^7, 2), "M")
      cds <- cdsBy(txdb, by = "tx")
      cds_count <- countOverlaps(bam,cds)
      CDS_reads[i] <- paste(round(sum(cds_count>0)/10^7, 2), "M")
      utr3 <- threeUTRsByTranscript(txdb)
      utr3_count <- countOverlaps(bam,utr3)
      UTR3_reads[i] <- paste(round(sum(utr3_count>0)/10^7, 2), "M")
      sum_component <- sum(utr5_count>0)+sum(cds_count>0)+sum(utr3_count>0)
      percent_UTR5[i] <- paste(round((sum(utr5_count>0)/(sum_component))*100,2), "%") 
      percent_CDS[i] <- paste(round((sum(cds_count>0)/(sum_component))*100,2), "%")
      percent_UTR3[i] <- paste((100-round((sum(utr5_count>0)/(sum_component))*100,2)-round((sum(cds_count>0)/(sum_component))*100,2)), "%")
    }
  }
  if(!is.na(sample_size)){
    sample_size<-as.numeric(sample_size)
    for (i in 1:noFiles) {
      print(paste("working on the ",i,"-th bam file ...",sep=""))
      bam <- readGAlignments(file[i])
      noR <- length(bam)
      id <- sample.int(noR,size=sample_size,replace=TRUE)
      bam <- bam[id]
      total_reads[i] <- paste(round(length(bam)/10^7,2), "M")
      bin_count <- countOverlaps(gc,bam)
      bin_count <- data.frame(bin_count)
      names(bin_count) <- sample_name[i]
      result2 <- data.frame(result2,bin_count)
      exon <- exonsBy(txdb, by = "tx")
      exon_count <- countOverlaps(bam,exon)
      exon_reads[i] <- paste(round(sum(exon_count>0)/10^7, 2), "M")
      intron <- intronsByTranscript(txdb)
      intron_count <- countOverlaps(bam,intron)
      intron_reads[i] <- paste(round(sum(intron_count>0)/10^7, 2), "M")
      percent_intron[i] <- paste(round((sum(intron_count>0)/(sum(intron_count>0)+sum(exon_count>0)))*100,2), "%")
      utr5 <- fiveUTRsByTranscript(txdb)
      utr5_count <- countOverlaps(bam,utr5)
      UTR5_reads[i] <- paste(round(sum(utr5_count>0)/10^7, 2), "M")
      cds <- cdsBy(txdb, by = "tx")
      cds_count <- countOverlaps(bam,cds)
      CDS_reads[i] <- paste(round(sum(cds_count>0)/10^7, 2), "M")
      utr3 <- threeUTRsByTranscript(txdb)
      utr3_count <- countOverlaps(bam,utr3)
      UTR3_reads[i] <- paste(round(sum(utr3_count>0)/10^7, 2), "M")
      sum_component <- sum(utr5_count>0)+sum(cds_count>0)+sum(utr3_count>0)
      percent_UTR5[i] <- paste(round((sum(utr5_count>0)/(sum_component))*100,2), "%") 
      percent_CDS[i] <- paste(round((sum(cds_count>0)/(sum_component))*100,2), "%")
      percent_UTR3[i] <- paste((100-round((sum(utr5_count>0)/(sum_component))*100,2)-round((sum(cds_count>0)/(sum_component))*100,2)), "%")
    }
    
  }
  read_alignment_summary <- cbind(sample_name,total_reads, exon_reads, intron_reads,percent_intron, UTR5_reads, CDS_reads, UTR3_reads,percent_UTR5, percent_CDS, percent_UTR3)
  read_alignment_summary<-as.data.frame(read_alignment_summary)
  # remove DNA regions
  i <- which(result2$comp=="Front") # remove front DNA
  result2 <- result2[-i,]
  i <- which(result2$comp=="Back") # remove tail DNA
  result<- result2[-i,]
  t<-data.frame(result)
  t1<-t[(t$category)=="mRNA",]
  t2<-t1[(t1$comp=="UTR5"),]
  t3<-t1[(t1$comp=="CDS"),]
  t3$pos+1->t3$pos
  t4<-t1[(t1$comp=="UTR3"),]
  t4$pos+2->t4$pos
  t0<-rbind(t2,t3,t4)
  s<-data.frame()
  s<-aggregate(cbind(t0[,6])~pos+txid,t0,mean)
  for(i in 7:length(t0))
  {
    
    w<-aggregate(cbind(t0[,i])~pos+txid,t0,mean)
    w<-w[,-(1:2)]
    s<-cbind(s,w)
  }
  s<-as.data.frame(s)
  colnames(s)<-c("pos","txid",sample_name)
  read_result<-list(s, read_alignment_summary,transform_table)
  return(read_result) 
}