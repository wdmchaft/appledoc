//
//  GBMarkdownOutputGenerator.m
//  appledoc
//
//  Created by Josh Weinberg
//

#import "RegexKitLite.h"
#import "GBStore.h"
#import "GBApplicationSettingsProvider.h"
#import "GBDataObjects.h"
#import "GBHTMLTemplateVariablesProvider.h"
#import "GBTemplateHandler.h"
#import "GBMarkdownOutputGenerator.h"

@interface GBMarkdownOutputGenerator ()

- (BOOL)validateTemplates:(NSError **)error;
- (BOOL)processClasses:(NSError **)error;
- (BOOL)processCategories:(NSError **)error;
- (BOOL)processProtocols:(NSError **)error;
//- (BOOL)processDocuments:(NSError **)error;
- (BOOL)processIndex:(NSError **)error;
- (BOOL)processHierarchy:(NSError **)error;
- (NSString *)stringByCleaningHtml:(NSString *)string;
- (NSString *)markdownOutputPathForIndex;
- (NSString *)markdownOutputPathForHierarchy;
- (NSString *)markdownOutputPathForObject:(GBModelBase *)object;
- (NSString *)markdownOutputPathForTemplateName:(NSString *)template;
@property (readonly) GBTemplateHandler *markdownObjectTemplate;
@property (readonly) GBTemplateHandler *markdownIndexTemplate;
@property (readonly) GBTemplateHandler *markdownHierarchyTemplate;
@property (readonly) GBTemplateHandler *markdownDocumentTemplate;
@property (readonly) GBHTMLTemplateVariablesProvider *variablesProvider;

@end

#pragma mark -

@implementation GBMarkdownOutputGenerator

#pragma Generation handling

- (BOOL)generateOutputWithStore:(id)store error:(NSError **)error {
	if (![super generateOutputWithStore:store error:error]) return NO;
	if (![self validateTemplates:error]) return NO;
	if (![self processClasses:error]) return NO;
	if (![self processCategories:error]) return NO;
	if (![self processProtocols:error]) return NO;
//	if (![self processDocuments:error]) return NO;
	if (![self processIndex:error]) return NO;
	if (![self processHierarchy:error]) return NO;
	return YES;
}

- (BOOL)processClasses:(NSError **)error {
	for (GBClassData *class in self.store.classes) {
        if (!class.includeInOutput) continue;
		GBLogInfo(@"Generating output for class %@...", class);
		NSDictionary *vars = [self.variablesProvider variablesForClass:class withStore:self.store];
		NSString *output = [self.markdownObjectTemplate renderObject:vars];
		NSString *cleaned = [self stringByCleaningHtml:output];
		NSString *path = [self markdownOutputPathForObject:class];
		if (![self writeString:cleaned toFile:[path stringByStandardizingPath] error:error]) {
			GBLogWarn(@"Failed writting HTML for class %@ to '%@'!", class, path);
			return NO;
		}
		GBLogDebug(@"Finished generating output for class %@.", class);
	}
	return YES;
}

- (BOOL)processCategories:(NSError **)error {
	for (GBCategoryData *category in self.store.categories) {
        if (!category.includeInOutput) continue;
		GBLogInfo(@"Generating output for category %@...", category);
		NSDictionary *vars = [self.variablesProvider variablesForCategory:category withStore:self.store];
		NSString *output = [self.markdownObjectTemplate renderObject:vars];
		NSString *cleaned = [self stringByCleaningHtml:output];
		NSString *path = [self markdownOutputPathForObject:category];
		if (![self writeString:cleaned toFile:[path stringByStandardizingPath] error:error]) {
			GBLogWarn(@"Failed writting HTML for category %@ to '%@'!", category, path);
			return NO;
		}
		GBLogDebug(@"Finished generating output for category %@.", category);
	}
	return YES;
}

- (BOOL)processProtocols:(NSError **)error {
	for (GBProtocolData *protocol in self.store.protocols) {
        if (!protocol.includeInOutput) continue;
		GBLogInfo(@"Generating output for protocol %@...", protocol);
		NSDictionary *vars = [self.variablesProvider variablesForProtocol:protocol withStore:self.store];
		NSString *output = [self.markdownObjectTemplate renderObject:vars];
		NSString *cleaned = [self stringByCleaningHtml:output];
		NSString *path = [self markdownOutputPathForObject:protocol];
		if (![self writeString:cleaned toFile:[path stringByStandardizingPath] error:error]) {
			GBLogWarn(@"Failed writting HTML for protocol %@ to '%@'!", protocol, path);
			return NO;
		}
		GBLogDebug(@"Finished generating output for protocol %@.", protocol);
	}
	return YES;
}

//- (BOOL)processDocuments:(NSError **)error {	
//	// First process all include paths by copying them over to the destination. Note that we do it even if no template is found - if the user specified some include path, we should use it...
//	NSString *docsUserPath = [self.outputUserPath stringByAppendingPathComponent:self.settings.markdownStaticDocumentsSubpath];
//	GBTemplateFilesHandler *handler = [[GBTemplateFilesHandler alloc] init];
//	for (NSString *path in self.settings.includePaths) {
//		GBLogInfo(@"Copying static documents from '%@'...", path);
//		NSString *lastComponent = [path lastPathComponent];
//		NSString *installPath = [docsUserPath stringByAppendingPathComponent:lastComponent];
//		handler.templateUserPath = path;
//		handler.outputUserPath = installPath;
//		if (![handler copyTemplateFilesToOutputPath:error]) return NO;
//	}
//	
//	// Now process all documents.
//	for (GBDocumentData *document in self.store.documents) {
//		GBLogInfo(@"Generating output for document %@...", document);
//		NSDictionary *vars = [self.variablesProvider variablesForDocument:document withStore:self.store];
//		NSString *output = [self.markdownDocumentTemplate renderObject:vars];
//		NSString *cleaned = [self stringByCleaningHtml:output];
//		NSString *path = [self markdownOutputPathForObject:document];
//		if (![self writeString:cleaned toFile:[path stringByStandardizingPath] error:error]) {
//			GBLogWarn(@"Failed writting HTML for document %@ to '%@'!", document, path);
//			return NO;
//		}
//		GBLogDebug(@"Finished generating output for document %@.", document);
//	}
//	return YES;
//}

- (BOOL)processIndex:(NSError **)error {
	GBLogInfo(@"Generating output for index...");
	if ([self.store.classes count] > 0 || [self.store.protocols count] > 0 || [self.store.categories count] > 0) {
		NSDictionary *vars = [self.variablesProvider variablesForIndexWithStore:self.store];
		NSString *output = [self.markdownIndexTemplate renderObject:vars];
		NSString *cleaned = [self stringByCleaningHtml:output];
		NSString *path = [[self markdownOutputPathForIndex] stringByStandardizingPath];
		if (![self writeString:cleaned toFile:[path stringByStandardizingPath] error:error]) {
			GBLogWarn(@"Failed writting HTML index to '%@'!", path);
			return NO;
		}
	}
	GBLogDebug(@"Finished generating output for index.");
	return YES;
}

- (BOOL)processHierarchy:(NSError **)error {
	GBLogInfo(@"Generating output for hierarchy...");
	if ([self.store.classes count] > 0 || [self.store.protocols count] > 0 || [self.store.categories count] > 0) {
		NSDictionary *vars = [self.variablesProvider variablesForHierarchyWithStore:self.store];
		NSString *output = [self.markdownHierarchyTemplate renderObject:vars];
		NSString *cleaned = [self stringByCleaningHtml:output];
		NSString *path = [[self markdownOutputPathForHierarchy] stringByStandardizingPath];
		if (![self writeString:cleaned toFile:[path stringByStandardizingPath] error:error]) {
			GBLogWarn(@"Failed writting HTML hierarchy to '%@'!", path);
			return NO;
		}
	}
	GBLogDebug(@"Finished generating output for hierarchy.");
	return YES;
}

- (BOOL)validateTemplates:(NSError **)error {
	if (!self.markdownObjectTemplate) {
		if (error) {
			NSString *desc = [NSString stringWithFormat:@"Object template file 'object-template.markdown' is missing at '%@'!", self.templateUserPath];
			*error = [NSError errorWithCode:GBErrorHTMLObjectTemplateMissing description:desc reason:nil];
		}
		return NO;
	}
	if (!self.markdownDocumentTemplate) {
		if (error) {
			NSString *desc = [NSString stringWithFormat:@"Document template file 'document-template.markdown' is missing at '%@'!", self.templateUserPath];
			*error = [NSError errorWithCode:GBErrorHTMLDocumentTemplateMissing description:desc reason:nil];
		}
		return NO;
	}
	if (!self.markdownIndexTemplate) {
		if (error) {
			NSString *desc = [NSString stringWithFormat:@"Index template file 'index-template.markdown' is missing at '%@'!", self.templateUserPath];
			*error = [NSError errorWithCode:GBErrorHTMLIndexTemplateMissing description:desc reason:nil];
		}
		return NO;
	}
	if (!self.markdownHierarchyTemplate) {
		if (error) {
			NSString *desc = [NSString stringWithFormat:@"Hierarchy template file 'hierarchy-template.markdown' is missing at '%@'!", self.templateUserPath];
			*error = [NSError errorWithCode:GBErrorHTMLHierarchyTemplateMissing description:desc reason:nil];
		}
		return NO;
	}
	return YES;
}

#pragma mark Helper methods

- (NSString *)stringByCleaningHtml:(NSString *)string {
	// Nothing to do at this point - as we're preserving all whitespace, we should be just fine with generated string. The method is still left as a placeholder for possible future handling.
	return string;
}

- (NSString *)markdownOutputPathForIndex {
	// Returns file name including full path for HTML file representing the main index.
	return [self markdownOutputPathForTemplateName:@"index-template.markdown"];
}

- (NSString *)markdownOutputPathForHierarchy {
	// Returns file name including full path for HTML file representing the main hierarchy.
	return [self markdownOutputPathForTemplateName:@"hierarchy-template.markdown"];
}

- (NSString *)markdownOutputPathForObject:(GBModelBase *)object {
	// Returns file name including full path for HTML file representing the given top-level object. This works for any top-level object: class, category or protocol. The path is automatically determined regarding to the object class. Note that we use the HTML reference to get us the actual path - we can't rely on template filename as it's the same for all objects...
#warning Doing weird things to test
    //	NSString *inner = [self.settings markdownReferenceForObjectFromIndex:object];
	return [self.outputUserPath stringByAppendingPathComponent:[object.htmlReferenceName stringByReplacingOccurrencesOfString:@".html" withString:@".markdown"]];
}

- (NSString *)markdownOutputPathForTemplateName:(NSString *)template {
	// Returns full path and actual file name corresponding to the given template.
	NSString *path = [self outputPathToTemplateEndingWith:template];
	NSString *filename = [self.settings outputFilenameForTemplatePath:template];
	return [path stringByAppendingPathComponent:filename];
}

- (GBHTMLTemplateVariablesProvider *)variablesProvider {
	static GBHTMLTemplateVariablesProvider *result = nil;
	if (!result) {
		GBLogDebug(@"Initializing variables provider...");
		result = [[GBHTMLTemplateVariablesProvider alloc] initWithSettingsProvider:self.settings];
	}
	return result;
}

- (GBTemplateHandler *)markdownObjectTemplate {
	return [self.templateFiles objectForKey:@"object-template.markdown"];
}

- (GBTemplateHandler *)markdownIndexTemplate {
	return [self.templateFiles objectForKey:@"index-template.markdown"];
}

- (GBTemplateHandler *)markdownHierarchyTemplate {
	return [self.templateFiles objectForKey:@"hierarchy-template.markdown"];
}

- (GBTemplateHandler *)markdownDocumentTemplate {
	return [self.templateFiles objectForKey:@"document-template.markdown"];
}

#pragma mark Overriden methods

- (NSString *)outputSubpath {
	return @"markdown";
}

@end
