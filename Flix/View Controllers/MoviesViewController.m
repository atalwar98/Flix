//
//  MoviesViewController.m
//  Flix
//
//  Created by atalwar98 on 6/26/19.
//  Copyright © 2019 atalwar98. All rights reserved.
//

#import "MoviesViewController.h"
#import "MovieCell.h"
#import "UIImageView+AFNetworking.h"
#import "DetailsViewController.h"

@interface MoviesViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *movies;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation MoviesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    // Start the activity indicator
    [self.activityIndicator startAnimating];
    
    [self fetchMovies];
    
    
    
    self.refreshControl = [[UIRefreshControl alloc] init];
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
            // create a cancel action
            UIAlertAction *tryAgainAction = [UIAlertAction actionWithTitle:@"Try Again"
            style:UIAlertActionStyleCancel
            handler:^(UIAlertAction * _Nonnull action) {
            // handle try again response here. Doing nothing will dismiss the view.
                // Start the activity indicator
                [self.activityIndicator startAnimating];
                [self fetchMovies];
}];
            // add the cancel action to the alertController
            [alert addAction:tryAgainAction];
            
            
            [self presentViewController:alert animated:YES completion:^{
                // optional code for what happens after the alert controller has finished presenting
            }];
        }
        else {
            NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            NSLog(@"%@", dataDictionary);
            // TODO: Get the array of movies
            self.movies = dataDictionary[@"results"];
            for (NSDictionary *movie in self.movies){
                NSLog(@"%@", movie[@"title"]);
            }

            [self.tableView reloadData];
        }
        [self.refreshControl endRefreshing];
        // Stop the activity indicator
        // Hides automatically if "Hides When Stopped" is enabled
        [self.activityIndicator stopAnimating];
    }];
    [task resume];
    
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.movies.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MovieCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MovieCell"];
    
    
    NSDictionary *movie = self.movies[indexPath.row];
    cell.titleLabel.text = movie[@"title"];
    cell.synopsisLabel.text = movie[@"overview"];
    
    NSString *baseURLString = @"https://image.tmdb.org/t/p/w500";
    NSString *posterURLString= movie[@"poster_path"];
    NSString *fullPosterURLString = [baseURLString stringByAppendingString:posterURLString];
    
    NSURL *posterURL = [NSURL URLWithString:fullPosterURLString];
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
    [cell.posterView setImageWithURL:posterURL];
    
    return cell;
}




 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
     
     UITableViewCell *tappedCell = sender;
     NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
     NSDictionary *movie = self.movies[indexPath.row];
     
     [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
     DetailsViewController *detailsViewController = [segue destinationViewController];
     
     detailsViewController.movie = movie;
     
 }

@end
