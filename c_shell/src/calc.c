/* ============================================================================
 *  Shell_POSIX-Core
 *  Author  : vidvathamaiiith
 *  Copyright (c) vidvathamaiiith. All Rights Reserved.
 *
 *  Built-in : calc   (inline arithmetic expression evaluator)
 *  ------------------------------------------------------------------------
 *  A self-contained recursive-descent expression evaluator built directly on
 *  top of the shell. It understands +, -, *, /, %, ^ (power), unary sign and
 *  parentheses, with full operator precedence and floating-point arithmetic.
 *  Because the shell reserves '*' as its internal pipe sentinel, calc parses
 *  its expression from the raw argument string rather than the space tokenizer
 *  so that multiplication ('3 * 4') is never mistaken for a pipe marker.
 *
 *  Usage:   calc <expression>          example: calc (3+4)*2 - 10/4
 *           calc <expression> > file   (redirection and | are supported)
 *
 *  Watermark: vidvathamaiiith
 * ==========================================================================*/
#include "../include/shell.h"

/* ---- recursive-descent parser state (single-threaded shell) -------------- */
static const char *cp;   /* current parse cursor */
static int calc_err;     /* set to 1 on any syntax/maths error */

static void skip_ws(void) { while (*cp == ' ' || *cp == '\t') cp++; }

static double parse_expr(void);   /* forward declaration */

/*  primary := number | '(' expr ')'  */
static double parse_primary(void) {
    skip_ws();
    if (*cp == '(') {
        cp++;
        double v = parse_expr();
        skip_ws();
        if (*cp == ')') cp++;
        else calc_err = 1;
        return v;
    }
    if (*cp != '.' && !isdigit((unsigned char)*cp)) {
        calc_err = 1;
        return 0.0;
    }
    char *endp;
    double v = strtod(cp, &endp);
    if (endp == cp) { calc_err = 1; return 0.0; }
    cp = endp;
    return v;
}

/*  unary := ('+'|'-') unary | primary  */
static double parse_unary(void) {
    skip_ws();
    if (*cp == '+') { cp++; return parse_unary(); }
    if (*cp == '-') { cp++; return -parse_unary(); }
    return parse_primary();
}

/*  power := unary ('^' power)?     (right associative)  */
static double parse_power(void) {
    double base = parse_unary();
    skip_ws();
    if (*cp == '^') {
        cp++;
        double e = parse_power();
        return pow(base, e);
    }
    return base;
}

/*  term := power (('*'|'/'|'%') power)*  */
static double parse_term(void) {
    double v = parse_power();
    for (;;) {
        skip_ws();
        char op = *cp;
        if (op == '*' || op == '/' || op == '%') {
            cp++;
            double rhs = parse_power();
            if (op == '*') {
                v = v * rhs;
            } else if (op == '/') {
                if (rhs == 0.0) { calc_err = 1; return 0.0; }
                v = v / rhs;
            } else { /* integer modulo */
                long long bi = (long long)rhs;
                if (bi == 0) { calc_err = 1; return 0.0; }
                v = (double)((long long)v % bi);
            }
        } else {
            break;
        }
    }
    return v;
}

/*  expr := term (('+'|'-') term)*  */
static double parse_expr(void) {
    double v = parse_term();
    for (;;) {
        skip_ws();
        char op = *cp;
        if (op == '+') { cp++; v += parse_term(); }
        else if (op == '-') { cp++; v -= parse_term(); }
        else break;
    }
    return v;
}

void handle_calc(char *args, int pipeo) {
    error = 0;

    char buf[600];
    strncpy(buf, args ? args : "", sizeof(buf) - 1);
    buf[sizeof(buf) - 1] = '\0';

    /* If this command pipes its output, the shell has appended a trailing '*'
     * sentinel. Strip it so it is not parsed as a dangling multiply. */
    if (pipeo) {
        for (int k = (int)strlen(buf) - 1; k >= 0; k--) {
            if (buf[k] == '*') { buf[k] = '\0'; break; }
            if (!isspace((unsigned char)buf[k])) break;
        }
    }

    /* Extract file redirection. Arithmetic expressions never contain '>'. */
    int output_redirect = 0, double_output_redirect = 0;
    char *output_file = NULL;
    char *gt = strchr(buf, '>');
    if (gt) {
        if (*(gt + 1) == '>') { double_output_redirect = 1; *gt = '\0'; gt += 2; }
        else { output_redirect = 1; *gt = '\0'; gt += 1; }
        while (*gt == ' ' || *gt == '\t') gt++;
        char *endf = gt + strlen(gt);
        while (endf > gt && (endf[-1] == ' ' || endf[-1] == '\t' || endf[-1] == '\n')) *(--endf) = '\0';
        if (*gt) output_file = strdup(gt);
    }

    if (pipeo) {
        user_pipe = 1;
        total_pipes--;
        if (output_file) free(output_file);
        output_file = strdup(pipe_file);
        output_redirect = 1;
    }

    /* Trim the expression text. */
    char *expr = buf;
    while (*expr == ' ' || *expr == '\t') expr++;
    char *ee = expr + strlen(expr);
    while (ee > expr && (ee[-1] == ' ' || ee[-1] == '\t' || ee[-1] == '\n')) *(--ee) = '\0';

    int saved_stdout = dup(STDOUT_FILENO);
    if (output_redirect && output_file != NULL) {
        int rfd = open(output_file, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (rfd < 0) { perror("failed to open/create redirected file\n"); close(saved_stdout); goto cleanup; }
        dup2(rfd, STDOUT_FILENO);
        close(rfd);
    } else if (double_output_redirect && output_file != NULL) {
        int rfd = open(output_file, O_WRONLY | O_CREAT | O_APPEND, 0644);
        if (rfd < 0) { perror("failed to open/create redirected file\n"); close(saved_stdout); goto cleanup; }
        dup2(rfd, STDOUT_FILENO);
        close(rfd);
    }

    if (*expr == '\0') {
        printf("calc: usage: calc <expression>\n");
        printf("  supported: + - * / %% ^ ( )    example: calc (3+4)*2 - 10/4\n");
    } else {
        cp = expr;
        calc_err = 0;
        double result = parse_expr();
        skip_ws();
        if (calc_err || *cp != '\0') {
            printf("calc: invalid expression: %s\n", expr);
            error = 1;
        } else if (isfinite(result) && fabs(result) < 9.2e18 &&
                   result == (double)(long long)result) {
            printf("%lld\n", (long long)result);
        } else {
            printf("%.10g\n", result);
        }
    }

    fflush(stdout);
    dup2(saved_stdout, STDOUT_FILENO);
    close(saved_stdout);
cleanup:
    if (output_file) free(output_file);
}
