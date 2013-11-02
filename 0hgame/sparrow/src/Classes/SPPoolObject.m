//
//  SPPoolObject.m
//  Sparrow
//
//  Created by Daniel Sperl on 17.09.09.
//  Copyright 2011 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPPoolObject.h"
#import "SPMacros.h"

#import <libkern/OSAtomic.h>
#import <malloc/malloc.h>
#import <objc/runtime.h>

#ifndef DISABLE_MEMORY_POOLING

// --- hash table ----------------------------------------------------------------------------------

#define HASH_MASK (SP_POOL_OBJECT_MAX_CLASSES - 1)

struct __SPPoolCachePair
{
    Class key;
    OSQueueHead value;
};
typedef struct __SPPoolCachePair SPPoolCachePair;

struct __SPPoolCache
{
    SPPoolCachePair table[SP_POOL_OBJECT_MAX_CLASSES];
};
typedef struct __SPPoolCache SPPoolCache;

SP_INLINE SPPoolCache* _cacheGetGlobal(void)
{
    static SPPoolCache instance = (SPPoolCache){{ nil, OS_ATOMIC_QUEUE_INIT }};
    return &instance;
}

SP_INLINE unsigned _cacheHashPtr(void* ptr)
{
#ifdef __LP64__
    return ((uintptr_t)ptr) >> 3;
#else
    return ((uintptr_t)ptr) >> 2;
#endif
}

SP_INLINE SPPoolCachePair* _cacheGetValue(SPPoolCache* cache, unsigned hash)
{
    return &cache->table[hash & HASH_MASK];
}

SP_INLINE void _cacheGlobalAddClass(Class class)
{
    SPPoolCache *cache = _cacheGetGlobal();
    unsigned hash = _cacheHashPtr(class);
    SPPoolCachePair *value = _cacheGetValue(cache, hash);

    value->key = class;
    value->value = (OSQueueHead)OS_ATOMIC_QUEUE_INIT;
}

SP_INLINE OSQueueHead* _cacheGlobalGetQueue(Class class)
{
    SPPoolCache *cache = _cacheGetGlobal();
    unsigned hash = _cacheHashPtr(class);
    SPPoolCachePair *value = _cacheGetValue(cache, hash);

    OSQueueHead *queue = NULL;
    if (value->key == class)
        queue = &value->value;

    return queue;
}

// --- queue ---------------------------------------------------------------------------------------

#define QUEUE_OFFSET sizeof(Class)

#if SP_POOL_OBJECT_IS_ATOMIC
    #define DEQUEUE(pool)       OSAtomicDequeue(pool, QUEUE_OFFSET)
    #define ENQUEUE(pool, obj)  OSAtomicEnqueue(pool, obj, QUEUE_OFFSET)
#else
    #define DEQUEUE(pool)       dequeue(pool)
    #define ENQUEUE(pool, obj)  enqueue(pool, obj)
#endif

void enqueue(OSQueueHead *list, void *new)
{
    *((void **)((char *)new + QUEUE_OFFSET)) = list->opaque1;
    list->opaque1 = new;
}

void* dequeue(OSQueueHead *list)
{
    void *head;

    head = list->opaque1;
    if (head != NULL) {
        void **next = (void **)((char *)head + QUEUE_OFFSET);
        list->opaque1 = *next;
    }

    return head;
}

// --- class implementation ------------------------------------------------------------------------

#if SP_POOL_OBJECT_IS_ATOMIC
    #define INCREMENT_32(var)    OSAtomicIncrement32Barrier(&var)
    #define DECREMENT_32(var)    OSAtomicDecrement32Barrier(&var)
    #define MEMORY_BARRIER()     OSMemoryBarrier()
#else
    #define INCREMENT_32(var)    (++ var)
    #define DECREMENT_32(var)    (-- var)
    #define MEMORY_BARRIER()
#endif

#define RETAIN_COUNT _refOrLink.ref

@implementation SPPoolObject
{
    union // since link is only used while in the queue
    {
        int32_t       ref;
        SPPoolObject *link;
    }
    _refOrLink;
}

+ (void)initialize
{
    if (self == [SPPoolObject class])
        return;

    _cacheGlobalAddClass(self);
}

+ (id)allocWithZone:(NSZone *)zone
{
  #if DEBUG && !SP_POOL_OBJECT_IS_ATOMIC
    // make sure that people don't use pooling from multiple threads
    static id thread = nil;
    if (thread) NSAssert(thread == [NSThread currentThread], @"SPPoolObject is NOT thread safe! Must set SP_POOL_OBJECT_IS_ATOMIC to 1.");
    else thread = [NSThread currentThread];
  #endif

    OSQueueHead *poolQueue = _cacheGlobalGetQueue(self);
    SPPoolObject *object = DEQUEUE(poolQueue);

    if (object)
    {
        // zero out memory. (do not overwrite isa, thus the offset)
        static size_t offset = sizeof(Class);
        memset((char *)(id)object + offset, 0, malloc_size(object) - offset);
        object->RETAIN_COUNT = 1;
    }
    else
    {
        // pool is empty -> allocate
        object = NSAllocateObject(self, 0, NULL);
        object->RETAIN_COUNT = 1;
    }

    return object;
}

- (NSUInteger)retainCount
{
    MEMORY_BARRIER();
    return RETAIN_COUNT;
}

- (instancetype)retain
{
    INCREMENT_32(RETAIN_COUNT);
    return self;
}

- (oneway void)release
{
    if (DECREMENT_32(RETAIN_COUNT) == 0)
    {
        OSQueueHead *poolQueue = _cacheGlobalGetQueue(object_getClass(self));
        ENQUEUE(poolQueue, self);
    }
}

- (void)purge
{
    // will call 'dealloc' internally -- which should not be called directly.
    [super release];
}

+ (NSUInteger)purgePool
{
    OSQueueHead *poolQueue = _cacheGlobalGetQueue(self);
    SPPoolObject *lastElement;

    NSUInteger count = 0;
    while ((lastElement = DEQUEUE(poolQueue)))
    {
        ++count;
        [lastElement purge];
    }

    return count;
}

@end

#else

@implementation SPPoolObject

+ (NSUInteger)purgePool
{
    return 0;
}

@end

#endif
