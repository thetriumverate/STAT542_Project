# STAT542_Project

##### Final Project for STAT542: [Springleaf Kaggle Competition](https://www.kaggle.com/c/springleaf-marketing-response)
### CODE
1. `clean_prep.R`
	* must change the working directory in script (but that's it) to the location of *train.csv* and *test.csv*
	* outputs intermediate files *train.rdata*, *test.rdata*, *Checkpoint2.csv*
	* outputs final file *cleaned_data.rdata*
	* ~24 minute runtime

2. `dim_reduction.R` 
	* again must change the working directory to where *cleaned_data.rdata* lives
	* Removes highly correlated variables and performs PCA
	* outputs intermediate file *corr_matrix.rdata*
	* outputs final files *reduced_data_train.rdata* and *reduced_data_test.rdata* which correspond to the data with redundant variables removed
	* outputs final files *PCA_data_train.rdata* and *PCA_data_test* which correspond to the PCA transformed data (numeric variables only)
	* ~ 28 minute runtime

3. 'xgboost.R' 
	* Performs XGBoost method on PCA data and original dataset
	* When running on the original dataset, the data is chunked into different subsets and then the xgboost is run on each subset and averaged

4. 'xgboost_bag.R'
	* Performs XGBoost using bagging on the original dataset

5. 'pca_script.R'
	* Generates a Random Forest (in parallel) on 10% and 50% of the PCA data
	* Then predicts on test data and writes csv's

6. 'reduced_script.R'
	* Generates a Random Forest (in parallel) on 10% and 50% of the reduced data
	* Then predicts on test data and writes csv's

7. 'xgb_bench.R'
	* Performs XGBoost on 50% and 100% of the reduced data
	* Then predicts on test data and writes csv's

### References 

Useful RF links:
- http://stackoverflow.com/questions/19170130/combining-random-forests-built-with-different-training-sets-in-r
- https://onlinecourses.science.psu.edu/stat857/node/179
- http://stats.stackexchange.com/questions/36165/does-the-optimal-number-of-trees-in-a-random-forest-depend-on-the-number-of-pred
- http://stackoverflow.com/questions/13956435/setting-values-for-ntree-and-mtry-for-random-forest-regression-model
- https://cran.r-project.org/web/packages/randomForest/randomForest.pdf
  	
Useful Git resources:
- https://help.github.com/articles/generating-ssh-keys/
- http://stackoverflow.com/questions/10032461/git-keeps-asking-me-for-my-ssh-key-passphrase
- https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes
- https://github.com/GarageGames/Torque2D/wiki/Cloning-the-repo-and-working-with-Git
- http://www.theodinproject.com/web-development-101/git-basics
- https://www.youtube.com/playlist?list=PL5-da3qGB5IBLMp7LtN8Nc3Efd4hJq0kD **very helpful**

  

