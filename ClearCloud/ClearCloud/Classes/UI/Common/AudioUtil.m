//
//  AudioUtil.m
//  ClearCloud
//
//  Created by Boris Katok on 10/1/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

#import "AudioUtil.h"

#define ATOM_PREAMBLE_SIZE    8
#define QT_ATOM BE_FOURCC
#define FREE_ATOM QT_ATOM('f', 'r', 'e', 'e')
#define JUNK_ATOM QT_ATOM('j', 'u', 'n', 'k')
#define MDAT_ATOM QT_ATOM('m', 'd', 'a', 't')
#define MOOV_ATOM QT_ATOM('m', 'o', 'o', 'v')
#define PNOT_ATOM QT_ATOM('p', 'n', 'o', 't')
#define SKIP_ATOM QT_ATOM('s', 'k', 'i', 'p')
#define WIDE_ATOM QT_ATOM('w', 'i', 'd', 'e')
#define PICT_ATOM QT_ATOM('P', 'I', 'C', 'T')
#define FTYP_ATOM QT_ATOM('f', 't', 'y', 'p')
#define UUID_ATOM QT_ATOM('u', 'u', 'i', 'd')
#define CMOV_ATOM QT_ATOM('c', 'm', 'o', 'v')
#define TRAK_ATOM QT_ATOM('t', 'r', 'a', 'k')
#define MDIA_ATOM QT_ATOM('m', 'd', 'i', 'a')
#define MINF_ATOM QT_ATOM('m', 'i', 'n', 'f')
#define STBL_ATOM QT_ATOM('s', 't', 'b', 'l')
#define STCO_ATOM QT_ATOM('s', 't', 'c', 'o')
#define CO64_ATOM QT_ATOM('c', 'o', '6', '4')

#define BE_32(x) (((uint32_t)(((uint8_t*)(x))[0]) << 24) |  \
(((uint8_t*)(x))[1]  << 16) |  \
(((uint8_t*)(x))[2]  <<  8) |  \
((uint8_t*)(x))[3])

#define BE_64(x) (((uint64_t)(((uint8_t*)(x))[0]) << 56) |  \
((uint64_t)(((uint8_t*)(x))[1]) << 48) |  \
((uint64_t)(((uint8_t*)(x))[2]) << 40) |  \
((uint64_t)(((uint8_t*)(x))[3]) << 32) |  \
((uint64_t)(((uint8_t*)(x))[4]) << 24) |  \
((uint64_t)(((uint8_t*)(x))[5]) << 16) |  \
((uint64_t)(((uint8_t*)(x))[6]) <<  8) |  \
((uint64_t)( (uint8_t*)(x))[7]))

#define BE_FOURCC(ch0, ch1, ch2, ch3)           \
( (uint32_t)(unsigned char)(ch3)        |   \
((uint32_t)(unsigned char)(ch2) <<  8) |   \
((uint32_t)(unsigned char)(ch1) << 16) |   \
((uint32_t)(unsigned char)(ch0) << 24) )

@implementation AudioUtil

- (NSString *)fixForFastPlayback:(char*)dest:(PHAsset*)selected
{
    FILE *infile  = NULL;
    FILE *outfile = NULL;
    uint32_t atom_type = 0;
    uint64_t atom_size = 0;
    uint64_t atom_offset = 0;
    uint64_t last_offset;
    uint64_t moov_atom_size;
    uint64_t ftyp_atom_size = 0;
    uint64_t i, j;
    uint32_t offset_count;
    uint64_t current_offset;
    uint64_t start_offset = 0;
    uint64_t start_offset_not_c = 0;
    uint64_t last_offset_not_c = 0;

    ALAssetRepresentation * rep = [selected defaultRepresentation];
    
    int bufferSize = 8192; // or use 8192 size as read from other posts
    
    int read = 0;
    NSError * err = nil;
    
    uint8_t * buffer = calloc(bufferSize, sizeof(*buffer));
    uint8_t * ftyp_atom;
    /* traverse through the atoms in the file to make sure that 'moov' is
     * at the end */
    int asset_offset = 0;
    while (asset_offset < [rep size])
    {
        
        read = [rep getBytes:buffer
                  fromOffset:asset_offset
                      length:ATOM_PREAMBLE_SIZE
                       error:&err];
        
        asset_offset += read;
        
        if (err != nil)
        {
            NSLog(@"Error: %@ %@", err, [err userInfo]);
        }
        
        
        atom_size = (uint32_t)BE_32(&buffer[0]);
        atom_type = BE_32(&buffer[4]);
        
        /* keep ftyp atom */
        if (atom_type == FTYP_ATOM) //no idea what an atom is, maybe a header or some sort of meta data or a file marker
        {
            
            ftyp_atom_size = atom_size;
            ftyp_atom = calloc(ftyp_atom_size, sizeof(*buffer));
            
            if (!ftyp_atom)
            {
                printf ("could not allocate %"PRIu64" byte for ftyp atom\n",
                        atom_size);
                
            }
            
            
            asset_offset -= ATOM_PREAMBLE_SIZE;
            
            read = [rep getBytes:ftyp_atom
                      fromOffset:asset_offset
                          length:ftyp_atom_size
                           error:&err];
            
            asset_offset += read;
            
            start_offset = asset_offset;
            
        }
        else
        {
            
            asset_offset += (atom_size - ATOM_PREAMBLE_SIZE);
            
        }
        
        printf("%c%c%c%c %10"PRIu64" %"PRIu64"\n",
               (atom_type >> 24) & 255,
               (atom_type >> 16) & 255,
               (atom_type >>  8) & 255,
               (atom_type >>  0) & 255,
               atom_offset,
               atom_size);
        if ((atom_type != FREE_ATOM) &&
            (atom_type != JUNK_ATOM) &&
            (atom_type != MDAT_ATOM) &&
            (atom_type != MOOV_ATOM) &&
            (atom_type != PNOT_ATOM) &&
            (atom_type != SKIP_ATOM) &&
            (atom_type != WIDE_ATOM) &&
            (atom_type != PICT_ATOM) &&
            (atom_type != UUID_ATOM) &&
            (atom_type != FTYP_ATOM))
        {
            printf ("encountered non-QT top-level atom (is this a Quicktime file?)\n");
            break;
        }
        atom_offset += atom_size;
        
        /* The atom header is 8 (or 16 bytes), if the atom size (which
         * includes these 8 or 16 bytes) is less than that, we won't be
         * able to continue scanning sensibly after this atom, so break. */
        if (atom_size < 8)
            break;
    }
    
    if (atom_type != MOOV_ATOM)
    {
        printf ("last atom in file was not a moov atom\n");
        free(ftyp_atom);
        fclose(infile);
        return 0;
    }
    
    asset_offset = [rep size];
    asset_offset -= atom_size;
    last_offset = asset_offset;
    
    
    
    moov_atom_size = atom_size;
    uint8_t * moov_atom = calloc(moov_atom_size, sizeof(*buffer));
    
    if (!moov_atom)
    {
        printf ("could not allocate %"PRIu64" byte for moov atom\n",
                atom_size);
        
    }
    read = [rep getBytes:moov_atom
              fromOffset:asset_offset
                  length:moov_atom_size
                   error:&err];
    
    asset_offset += read;
    
    /* this utility does not support compressed atoms yet, so disqualify
     * files with compressed QT atoms */
    if (BE_32(&moov_atom[12]) == CMOV_ATOM)
    {
        printf ("this utility does not support compressed moov atoms yet\n");
        
    }
    
    /* crawl through the moov chunk in search of stco or co64 atoms */
    for (i = 4; i < moov_atom_size - 4; i++)
    {
        atom_type = BE_32(&moov_atom[i]);
        
        if (atom_type == STCO_ATOM)
        {
            printf (" patching stco atom...\n");
            atom_size = BE_32(&moov_atom[i - 4]);
            if (i + atom_size - 4 > moov_atom_size)
            {
                printf (" bad atom size\n");
                
            }
            offset_count = BE_32(&moov_atom[i + 8]);
            for (j = 0; j < offset_count; j++)
            {
                current_offset = BE_32(&moov_atom[i + 12 + j * 4]);
                current_offset += moov_atom_size;
                moov_atom[i + 12 + j * 4 + 0] = (current_offset >> 24) & 0xFF;
                moov_atom[i + 12 + j * 4 + 1] = (current_offset >> 16) & 0xFF;
                moov_atom[i + 12 + j * 4 + 2] = (current_offset >>  8) & 0xFF;
                moov_atom[i + 12 + j * 4 + 3] = (current_offset >>  0) & 0xFF;
            }
            i += atom_size - 4;
        }
        else if (atom_type == CO64_ATOM)
        {
            
            printf (" patching co64 atom...\n");
            atom_size = BE_32(&moov_atom[i - 4]);
            if (i + atom_size - 4 > moov_atom_size)
            {
                printf (" bad atom size\n");
                
            }
            offset_count = BE_32(&moov_atom[i + 8]);
            for (j = 0; j < offset_count; j++)
            {
                current_offset = BE_64(&moov_atom[i + 12 + j * 8]);
                current_offset += moov_atom_size;
                moov_atom[i + 12 + j * 8 + 0] = (current_offset >> 56) & 0xFF;
                moov_atom[i + 12 + j * 8 + 1] = (current_offset >> 48) & 0xFF;
                moov_atom[i + 12 + j * 8 + 2] = (current_offset >> 40) & 0xFF;
                moov_atom[i + 12 + j * 8 + 3] = (current_offset >> 32) & 0xFF;
                moov_atom[i + 12 + j * 8 + 4] = (current_offset >> 24) & 0xFF;
                moov_atom[i + 12 + j * 8 + 5] = (current_offset >> 16) & 0xFF;
                moov_atom[i + 12 + j * 8 + 6] = (current_offset >>  8) & 0xFF;
                moov_atom[i + 12 + j * 8 + 7] = (current_offset >>  0) & 0xFF;
            }
            i += atom_size - 4;
        }
    }
    
    outfile = fopen(dest, "wb");
    NSLog(@"%llu",last_offset);
    
    //global variables to be used when returning the actual data
    start_offset_not_c = start_offset;
    last_offset_not_c = last_offset;
    
    if (ftyp_atom_size > 0)
    {
        printf ("writing ftyp atom...\n");
        if (fwrite(ftyp_atom, ftyp_atom_size, 1, outfile) != 1)
        {
            perror(dest);
        }
    }
    
    printf ("writing moov atom...\n");
    if (fwrite(moov_atom, moov_atom_size, 1, outfile) != 1)
    {
        perror(dest);
    }
    
    fclose(outfile);
    free(ftyp_atom);
    free(moov_atom);
    ftyp_atom = NULL;
    moov_atom = NULL;
    
    return [NSString stringWithCString:dest encoding:NSStringEncodingConversionAllowLossy];
}

@end
