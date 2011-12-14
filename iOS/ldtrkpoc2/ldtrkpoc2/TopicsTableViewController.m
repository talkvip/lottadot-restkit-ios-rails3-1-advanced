//
//  LDTViewController.m
//  ldtrkpoc2
//
//  Created by Shane Zatezalo on 12/8/11.
//  Copyright (c) 2011 Personal. All rights reserved.
//

#import "TopicsTableViewController.h"
#import <CoreData/CoreData.h>
#import "CoreDataTableViewController.h"
#import "MyModelEntities.h"
#import <RestKit/RestKit.h>

@interface TopicsTableViewController (Private)
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)setupFetchedResultsController;
- (void)fetchTopicDataFromRemote;
@end

@implementation TopicsTableViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (nil == self.fetchedResultsController) {
        [self setupFetchedResultsController];
    }
    [self fetchTopicDataFromRemote];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark -
#pragma mark Table view methods


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *reuseIdentifier = @"Topic Cell";
    
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (nil == cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	}
    [self configureCell:cell atIndexPath:indexPath];
	return cell;
}

#pragma mark - Table Cell 

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {   
    //TODO
    Topic *topic = (Topic *)[self.fetchedResultsController objectAtIndexPath:indexPath];
	//cell.textLabel.text = @"something"; // [[aPost objectAtIndex:indexPath.row] title];
    cell.textLabel.text = [topic title];
}


#pragma mark -
#pragma mark Fetched results controller

- (void)setupFetchedResultsController // attaches an NSFetchRequest to this UITableViewController
{
    if (nil == self.fetchedResultsController) {       
        NSManagedObjectContext *managedObjectContext = [ApplicationDelegate managedObjectContext];

        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Topic"];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
        // no predicate because we want ALL the Topics
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:managedObjectContext
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:nil];
            
        
    }
}

- (void)fetchTopicDataFromRemote {
    // Load the object model via RestKit	
    RKObjectManager* objectManager = [RKObjectManager sharedManager];
    [objectManager loadObjectsAtResourcePath:@"/topics" delegate:self 
                                       block:^(RKObjectLoader* loader) {
        // The backend returns topics as a naked array in JSON, so we instruct the loader
        // to user the appropriate object mapping
        loader.objectMapping = [objectManager.mappingProvider objectMappingForClass:[Topic class]];
    }];
}

#pragma mark RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastUpdatedAt"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	NSLog(@"Loaded topics: %@", objects);
	//[self loadObjectsFromDataStore];
    [self performFetch];
	[self.tableView reloadData];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                     message:[error localizedDescription] 
                                                    delegate:nil 
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
	[alert show];
	NSLog(@"Hit error: %@", error);
}

#pragma mark Segue

// Support segueing from this table to any view controller that has a Topic @property.

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    Topic *clicked = [self.fetchedResultsController objectAtIndexPath:indexPath];
    // be somewhat generic here (slightly advanced usage)
    // we'll segue to ANY view controller that has a photographer @property
    if ([segue.destinationViewController respondsToSelector:@selector(setTopic:)]) {
        // use performSelector:withObject: to send without compiler checking
        // (which is acceptable here because we used introspection to be sure this is okay)
        [segue.destinationViewController performSelector:@selector(setTopic:) withObject:clicked];
    }
}

@end