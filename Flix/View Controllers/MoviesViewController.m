//
//  MoviesViewController.m
//  Flix
//
//  Created by atalwar98 on 6/26/19.
//  Copyright © 2019 atalwar98. All rights reserved.
//

#import "MoviesViewController.h"
#import "MovieCell.h"
//AFNetworking library adds a few fxns to existing library UIImageView
#import "UIImageView+AFNetworking.h"
#import "DetailsViewController.h"

@interface MoviesViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) NSArray *movies;
@property (nonatomic, strong) NSArray *filteredMovies;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UISearchBar *movieSearch;


@end

@implementation MoviesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    //notifying tableView that moviesViewController is both its datasource and delegate; so, datasource/delegate methods are in this controller class
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.movieSearch.delegate = self;
    
    [self.activityIndicator startAnimating];
    
    //fetch data from API
    [self fetchMovies];
    
    //initialization of pull to refresh feature
    self.refreshControl = [[UIRefreshControl alloc] init];
    
    //adding target-action pair programmatically; calls fetchMovies method on this class when user performs refresh action
    [self.refreshControl addTarget:self action:@selector(fetchMovies) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
    
}

- (void) fetchMovies {
    NSURL *url = [NSURL URLWithString:@"https://api.themoviedb.org/3/movie/now_playing?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Movies!"
                message:@"You seem to be offline. Please check your internet connection."
                preferredStyle:(UIAlertControllerStyleAlert)];
            
            UIAlertAction *tryAgainAction = [UIAlertAction actionWithTitle:@"Try Again" // create a Try Again action
            style:UIAlertActionStyleCancel
            handler:^(UIAlertAction * _Nonnull action) {
            // handle Try Again response here. Doing nothing will dismiss the view.
                // Start the activity indicator
                [self.activityIndicator startAnimating];
                [self fetchMovies];
}];
            
            [alert addAction:tryAgainAction]; // add the try again action to the alertController
            
            [self presentViewController:alert animated:YES completion:^{
            // optional code for what happens after the alert controller has finished presenting
            }];
        }
        else {
            NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            NSLog(@"%@", dataDictionary);
            self.movies = dataDictionary[@"results"]; //array of movies
            self.filteredMovies = self.movies;
            for (NSDictionary *movie in self.movies){
                NSLog(@"%@", movie[@"title"]);
            }
            //triggers calling datasource methods again since movies array could have changed after obtaining data
            [self.tableView reloadData];
        }
        //end pull to refresh feature once the movie data has been obtained from the API
        [self.refreshControl endRefreshing];
        
        // Stop the activity indicator
        // Hides automatically if "Hides When Stopped" is enabled
        [self.activityIndicator stopAnimating];
    }];
    [task resume];
    
}

//datasource method #1
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredMovies.count;
}

//datasource method #2
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MovieCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MovieCell"];
    
    NSDictionary *movie = self.filteredMovies[indexPath.row];
    cell.titleLabel.text = movie[@"title"];
    cell.synopsisLabel.text = movie[@"overview"];
    
    NSString *baseURLString = @"https://image.tmdb.org/t/p/w500";
    NSString *posterURLString= movie[@"poster_path"];
    NSString *fullPosterURLString = [baseURLString stringByAppendingString:posterURLString];
    
    //convert URL in string format into URL type
    NSURL *posterURL = [NSURL URLWithString:fullPosterURLString];
    
    //clears out previous image before downloading the new one; doing so prevents previous image from momentarily appearing when it is dequeued
    cell.posterView.image = nil;
    NSURLRequest *request = [NSURLRequest requestWithURL:posterURL];

    __weak MovieCell *weakCell = cell;
    [cell.posterView setImageWithURLRequest:request placeholderImage:nil
    success:^(NSURLRequest *imageRequest, NSHTTPURLResponse *imageResponse, UIImage *image) {
                                        
    // imageResponse will be nil if the image is cached
    if (imageResponse) {
        NSLog(@"Image was NOT cached, fade in image");
        weakCell.posterView.alpha = 0.0;
        weakCell.posterView.image = image;
                                            
        //Animate UIImageView back to alpha 1 over 0.3sec
        [UIView animateWithDuration:0.8 animations:^{
        weakCell.posterView.alpha = 1.0;
                                            }];
        }
                                       
    }
    failure:^(NSURLRequest *request, NSHTTPURLResponse * response, NSError *error) {
        // do something for the failure condition
    }];
    //this method is obtained from the AFNetworking 3rd party library
    [cell.posterView setImageWithURL:posterURL];
    
    return cell;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    if (searchText.length != 0) {
        
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *evaluatedObject, NSDictionary *bindings) {
            return [evaluatedObject[@"title"] containsString:searchText];
        }];
        self.filteredMovies = [self.movies filteredArrayUsingPredicate:predicate];
        
        NSLog(@"%@", self.filteredMovies);
        
    }
    else {
        self.filteredMovies = self.movies;
    }
    
    [self.tableView reloadData];
    
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.movieSearch.showsCancelButton = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.movieSearch.showsCancelButton = NO;
    self.movieSearch.text = @"";
    [self.movieSearch resignFirstResponder];
}





 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 
 // Pass the selected object to the new view controller.
     
     //reference to the cell the user tapped
     UITableViewCell *tappedCell = sender;
     
     //obtain index of cell via indexPath
     NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
     
     //obtain particular movie (dictionary) that user tapped
     NSDictionary *movie = self.movies[indexPath.row];
     
     
     [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
     
     // Get the new view controller using [segue destinationViewController]
     DetailsViewController *detailsViewController = [segue destinationViewController];
     
     //set the public movie instance var in the details controller to be the one the user tapped on so that the details controller has access to all the relevant info
     detailsViewController.movie = movie;
     
 }

@end
