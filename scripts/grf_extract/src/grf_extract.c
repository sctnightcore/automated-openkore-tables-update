#include <grf.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int glob( const char *c, const char *s );
void usage();

int main(int argc, char** argv) {
  char* grf_file = NULL;
  char* grf_path = NULL;
  char* out_path = NULL;
  int opt_glob = 0;
  int i;
  for (i = 1 ; i < argc ; i++) {
    if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help")) {
      usage(argv[0]);
      return 1;
    } else if (!strcmp(argv[i], "-g") || !strcmp(argv[i], "--glob")) {
      opt_glob = 1;
    } else if (grf_file == NULL) {
      grf_file = argv[i];
    } else if (grf_path == NULL) {
      grf_path = argv[i];
    } else if (out_path == NULL) {
      out_path = argv[i];
    }
  }
  if (grf_file == NULL) {
    usage(argv[0]);
    return 1;
  }
  printf("Loading GRF: %s\n", grf_file);
  grf_handle grf = grf_load(grf_file, 0);
  int filecount = grf_filecount(grf);
  printf("  # of files: %d\n", filecount);
  grf_node* files = grf_get_file_id_list(grf);
  for ( grf_node *ptr = files; *ptr ; ptr++ ) {
      const char* filename = grf_file_get_filename(*ptr);
      int filesize = grf_file_get_size(*ptr);
      if (grf_path == NULL) {
          printf("  %s (%d)\n", filename, filesize);
      } else if ((!opt_glob && !strcmp(grf_path,filename)) || (opt_glob && !glob(grf_path,filename))) {
          const char* basename = grf_file_get_basename(*ptr);
          if (out_path != NULL) basename = out_path;
          printf("  Extracting %s (%d) to %s\n", filename, filesize, basename);
          grf_put_contents_to_file(*ptr, basename);
      }
  }
  return 0;
}

void usage(char* progname) {
  printf("%s file.grf file_to_extract [file_to_save_as]\n", progname);
  printf("  -g --glob    treat file_to_extract as a globbing pattern\n");
  printf("  -h --help    this help\n");
}

# define CHECK_BIT( tab, bit ) ( tab[ (bit)/8 ] & (1<<( (bit)%8 )) )
# define BITLISTSIZE 16	/* bytes used for [chars] in compiled expr */

static void globchars( const char *s, const char *e, char *b );

/*
 * glob() - match a string against a simple pattern
 */

int glob( const char *c, const char *s ) {
	char bitlist[ BITLISTSIZE ];
	const char *here;

	for( ;; )
	    switch( *c++ )
	{
	case '\0':
		return *s ? -1 : 0;

	case '?':
		if( !*s++ )
		    return 1;
		break;

	case '[':
		/* scan for matching ] */

		here = c;
		do if( !*c++ )
			return 1;
		while( here == c || *c != ']' );
		c++;

		/* build character class bitlist */

		globchars( here, c, bitlist );

		if( !CHECK_BIT( bitlist, *(unsigned char *)s ) )
			return 1;
		s++;
		break;

	case '*':
		here = s;

		while( *s ) 
			s++;

		/* Try to match the rest of the pattern in a recursive */
		/* call.  If the match fails we'll back up chars, retrying. */

		while( s != here )
		{
			int r;

			/* A fast path for the last token in a pattern */

			r = *c ? glob( c, s ) : *s ? -1 : 0;

			if( !r )
				return 0;
			else if( r < 0 )
				return 1;

			--s;
		}
		break;

	case '\\':
		/* Force literal match of next char. */

		if( !*c || *s++ != *c++ )
		    return 1;
		break;

	default:
		if( *s++ != c[-1] )
		    return 1;
		break;
	}
}

/*
 * globchars() - build a bitlist to check for character group match
 */

static void globchars( const char *s, const char *e, char *b ) {
	int neg = 0;

	memset( b, '\0', BITLISTSIZE  );

	if( *s == '^') 
		neg++, s++;

	while( s < e )
	{
		int c;

		if( s+2 < e && s[1] == '-' )
		{
			for( c = s[0]; c <= s[2]; c++ )
				b[ c/8 ] |= (1<<(c%8));
			s += 3;
		} else {
			c = *s++;
			b[ c/8 ] |= (1<<(c%8));
		}
	}
			
	if( neg )
	{
		int i;
		for( i = 0; i < BITLISTSIZE; i++ )
			b[ i ] ^= 0377;
	}

	/* Don't include \0 in either $[chars] or $[^chars] */

	b[0] &= 0376;
}
