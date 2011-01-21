//
//  PSTableViewController.m
//  PSFoundation
//
//  Created by Peter Steinberger on 05.10.10.
//  Copyright 2010 Peter Steinberger. All rights reserved.
//

#import "PSTableViewController.h"

@interface PSTableViewController ()
@end

// http://cocoawithlove.com/2009/03/recreating-uitableviewcontroller-to.html
@implementation PSTableViewController

@synthesize tableViewStyle = _tableViewStyle, useShadows;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSObject

- (id)init {
  if((self = [self initWithStyle:UITableViewStylePlain])) {
  }
  return self;
}

- (id)initWithStyle:(UITableViewStyle)tableViewStyle {
  if ((self = [super init])) {
    _tableViewStyle = tableViewStyle;
  }
  return self;
}

- (void)dealloc {
  [tableView setDelegate:nil];
  [tableView setDataSource:nil];
  [tableView release];

  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIView

/*
- (void)loadView {
  [super loadView];

  if (self.nibName) {
    NSAssert(tableView != nil, @"NIB file did not set tableView property.");
    return;
  }

  self.view = newTableView;
  self.tableView = newTableView;
}*/

- (void)viewDidLoad {
  [super viewDidLoad];

  UITableView *newTableView = [self createTableView];
  newTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  newTableView.frame = self.view.bounds;
  [self.view addSubview:newTableView];
  self.tableView = newTableView;
}

- (void)viewDidUnload {
  [tableView release]; tableView = nil;
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [self.tableView reloadData];
  // how to deselect?
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  [self.tableView flashScrollIndicators];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties

// can be overridden!
- (UITableView *)createTableView {
  UITableView *newTableView;
  newTableView = [[[UITableView alloc] initWithFrame:CGRectZero style:self.tableViewStyle] autorelease];

  return newTableView;
}

- (UITableView *)tableView {
  return tableView;
}

- (void)setTableView:(UITableView *)newTableView {
  if ([tableView isEqual:newTableView])
  {
    return;
  }
  [tableView release];
  tableView = [newTableView retain];
  [tableView setDelegate:self];
  [tableView setDataSource:self];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return nil;
}


@end
