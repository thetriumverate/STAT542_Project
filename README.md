# STAT542_Project

### Final Project for STAT542: [Springleaf Kaggle Competition](https://www.kaggle.com/c/springleaf-marketing-response)

##### TO DO

1. **Clean and Prepare Data** (see[here](https://www.kaggle.com/darraghdog/springleaf-marketing-response/explore-springleaf/notebook))
	* Impute numeric Variables
	* Collapse Levels of Categorical Variables (including parsing dates)
	* Remove problem variables
	* Remove Redundant Variables

Note: We should combine training and test sets before doing step 1, then separate again for step 2.

2. **Dimension Reduction**
	* Factor analysis/PCA (although Brieman says "dimensionality can be a blessing")
	* Variable Selection

3. **Algorithm Implementation**
	* Split data into samples
	* Construct one tree per sample
	* Combine trees into forest

4. **Benchmarking**
	* Check our algorithm vs. Random forest on subset
	* other methods


##### References 

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

  

