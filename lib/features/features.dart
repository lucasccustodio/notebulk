/*
  Features

  Features are a variant of EntityManagerProvider that create and manage their own EntityManager instance. 
  They allow the app to run logic isolated from the main execution context which includes having control over what systems will be run or entities copied from the main EntityManager with the lifecycle callback onCreate, and any changes made can be later transmitted, if needed, to the main EntityManager using the lifecycle callback onDestroy. 
  
  For example, when creating or editing a note there's no need to have any system being active on the background, so a isolated context is ideal not only for performance but predictability.
*/

export 'noteFormFeature.dart';
export 'reminderFormFeature.dart';
