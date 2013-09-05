/* Copyright (C) 2003-2005 Mandriva SA  Daouda Lo (daouda) 
 * This program is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <grp.h>
#include <pwd.h>
#include <crypt.h>
#include <ctype.h>
#include <dirent.h>
#include <fcntl.h>
#include <locale.h>
#include <limits.h>
#include <sys/signal.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <glib.h>
#include <utime.h>
#include <libuser/user.h>
#include <libuser/user_private.h>



#define INVALID (-0x80000000)
#ifndef _
#define _(String) gettext(String)
#endif
#ifndef N_
#define N_(String) (String)
#endif

typedef struct lu_context USER__ADMIN;
typedef struct lu_ent USER__ENT;
typedef struct lu_error USER__ERR;


MODULE = USER       PACKAGE = USER::ADMIN         PREFIX = Admin_

USER::ADMIN *
Admin_new(CLASS)
        char *CLASS
        CODE:
        USER__ERR *error = NULL;
        RETVAL = (USER__ADMIN *)lu_start(NULL, 0, NULL, NULL, lu_prompt_console_quiet, NULL, &error);
        if( RETVAL == NULL ){
                warn("unable to malloc USER__ADMIN");
                XSRETURN_UNDEF;
	}
        OUTPUT:
        RETVAL

void        
Admin_DESTROY(self)
        USER::ADMIN *self
        CODE:
        if (self) lu_end(self);

int
Admin_UserAdd(self, ent, is_system, dont_create_home)
        USER::ADMIN *self
        USER::ENT *ent
        int is_system
        int dont_create_home
        CODE:
        USER__ERR *error = NULL;
        long uidNumber, gidNumber;
        char *skeleton = "/etc/skel", *homeDirectory = NULL;
        GValueArray *values; 
        GValue *value;
        /* GMOT (Great Moment Of Truth) */
        if (lu_user_add(self, ent, &error) == FALSE) {
             croak(_("Account creation failed: '%s'.\n"), error ? error->string : "Unknown error");
                RETVAL = 0;
        } else RETVAL = 1 ;
        if (!dont_create_home) {
                /* Read the user's UID. */
                values = lu_ent_get(ent, LU_UIDNUMBER);
                value = g_value_array_get_nth(values, 0);
                if (G_VALUE_HOLDS_LONG(value)) {
                        uidNumber = g_value_get_long(value);
                } else
                if (G_VALUE_HOLDS_STRING(value)) {
                        uidNumber = atol(g_value_get_string(value));
                } else {
                     warn(_("Cannot get Uid number"));
                }

                /* Read the user's GID. */
                values = lu_ent_get(ent, LU_GIDNUMBER);
                value = g_value_array_get_nth(values, 0);
                if (G_VALUE_HOLDS_LONG(value)) {
                        gidNumber = g_value_get_long(value);
                } else
                if (G_VALUE_HOLDS_STRING(value)) {
                        gidNumber = atol(g_value_get_string(value));
                } else {
                     warn(_("Cannot retrieve value"));
                }

                /* Read the user's home directory. */
                values = lu_ent_get(ent, LU_HOMEDIRECTORY);
                value = g_value_array_get_nth(values, 0);
                homeDirectory = g_value_get_string(value);
                
                if (lu_homedir_populate(self, skeleton, homeDirectory,
                                        uidNumber, gidNumber, 0700,
                                        &error) == 0) {
                        warn(_("Error creating `%s': %s"), homeDirectory, error ? error->string : "unknown error");
                        RETVAL = 2;
                }

                /* Create a mail spool for the user. */
                if (lu_mail_spool_create(self, ent, &error) != 1) {
                        warn(_("Error creating mail spool: %s\n"), error ? error->string : "Unknown error");
                        RETVAL = 3;
                }
        }
        OUTPUT:
        RETVAL

int
Admin_IsLocked(self, ent)
        USER::ADMIN *self
        USER::ENT *ent
        CODE:
        USER__ERR *error = NULL;
        if (lu_user_islocked(self, ent, &error)) {
                RETVAL = 1; 
        } else { RETVAL = 0; };
        OUTPUT:
        RETVAL

int
Admin_Lock(self, ent)
        USER::ADMIN *self
        USER::ENT *ent
        CODE:
        USER__ERR *error = NULL;
        if (lu_user_lock(self, ent, &error) == FALSE) {
                RETVAL = 0; 
        } else { RETVAL = 1; };
        OUTPUT:
        RETVAL

int
Admin_UnLock(self, ent)
        USER::ADMIN *self
        USER::ENT *ent
        CODE:
        USER__ERR *error = NULL;
        if (lu_user_unlock(self, ent, &error) == FALSE) {
                RETVAL = 0;
        } else { RETVAL = 1; };
        OUTPUT:
        RETVAL

void 
Admin_UserModify(self, ent)
        USER::ADMIN *self
        USER::ENT *ent
        PPCODE:
        USER__ERR *error = NULL;
        if (lu_user_modify(self, ent, &error) == FALSE) {
             croak(_("User could not be modified: '%s'.\n"), error ? error->string : "Unknown error");
        }

int
Admin_UserDel(self, ent)
        USER::ADMIN *self
        USER::ENT *ent
        CODE:
        USER__ERR *error = NULL;
        if (lu_user_delete(self, ent, &error) == FALSE) {
             croak(_("User Could Not be deleted: '%s'.\n"), error ? error->string : "Unknown error");
                RETVAL = 0;
        } else RETVAL = 1 ;
        OUTPUT:
        RETVAL

void
Admin_InitUser(self, name, is_system)
        USER::ADMIN *self
        char *name
        int is_system
        PPCODE:
        USER__ENT *ent;
        ent = lu_ent_new();
        lu_user_default(self, name, is_system, ent);
        XPUSHs(sv_2mortal(sv_bless(newRV_noinc(newSViv(ent)), gv_stashpv("USER::ENT", 1))));

void
Admin_UserSetPass(self, ent, userPasswd)
        USER::ADMIN *self
        USER::ENT *ent
        char *userPasswd
        PPCODE:
        USER__ERR *error = NULL;
        gboolean crypted = FALSE;
	if (lu_user_setpass(self, ent, userPasswd, crypted, &error) == FALSE) {
             croak(_("Failed to set password: '%s'.\n"), error ? error->string : _("unknown error"));
                if (error) { lu_error_free(&error); }
        }

void
Admin_LookupUserByName(self, name)
        USER::ADMIN *self
        char *name
        PPCODE:
        USER__ENT *ent;
        USER__ERR *error = NULL;
        ent = lu_ent_new();
        if (lu_user_lookup_name(self, name, ent, &error)) {
                XPUSHs(sv_2mortal(sv_bless(newRV_noinc(newSViv(ent)), gv_stashpv("USER::ENT", 1))));
        } else {
                lu_ent_free(ent);
        }

void
Admin_LookupUserById(self, id)
        USER::ADMIN *self
        long id
        PPCODE:
        USER__ENT *ent;
        USER__ERR *error = NULL;
        ent = lu_ent_new();
        if (lu_user_lookup_id(self, id, ent, &error)) {
                XPUSHs(sv_2mortal(sv_bless(newRV_noinc(newSViv(ent)), gv_stashpv("USER::ENT", 1))));
        } else {
                lu_ent_free(ent);
        }

void
Admin_LookupGroupByName(self, name)
        USER::ADMIN *self
        char *name
        PPCODE:
        USER__ENT *ent;
        USER__ERR *error = NULL;
        ent = lu_ent_new();
        if (lu_group_lookup_name(self, name, ent, &error)) {
                XPUSHs(sv_2mortal(sv_bless(newRV_noinc(newSViv(ent)), gv_stashpv("USER::ENT", 1))));
        } else {
                lu_ent_free(ent);
        }

void
Admin_LookupGroupById(self, id)
        USER::ADMIN *self
        int id
        PPCODE:
        USER__ENT *ent;
        USER__ERR *error = NULL;
        ent = lu_ent_new();
        if (lu_group_lookup_id(self, id, ent, &error)) {
                XPUSHs(sv_2mortal(sv_bless(newRV_noinc(newSViv(ent)), gv_stashpv("USER::ENT", 1))));
        } else {
                lu_ent_free(ent);
        }

void 
Admin_GroupAdd(self, ent)
        USER::ADMIN *self
        USER::ENT *ent
        PPCODE:
        USER__ERR *error = NULL;
        if (lu_group_add(self, ent, &error) == FALSE) {
             warn(_("Group creation failed.\n"));
        }

void
Admin_GroupModify(self, ent)
        USER::ADMIN *self
        USER::ENT *ent
        PPCODE:
        USER__ERR *error = NULL;
        if (lu_group_modify(self, ent, &error) == FALSE) {
             croak(_("Group could not be modified: '%s'.\n"), error ? error->string : "Unknown error");
        }

int
Admin_GroupDel(self, ent)
        USER::ADMIN *self
        USER::ENT *ent
        CODE:
        USER__ERR *error = NULL;
        if (lu_group_delete(self, ent, &error) == FALSE) {
             croak(_("Group could not be deleted: '%s'.\n"), error ? error->string : "Unknown error");
                RETVAL = 0;
        } else RETVAL = 1 ;
        OUTPUT:
        RETVAL

void
Admin_InitGroup(self, name, is_system)
        USER::ADMIN *self
        char *name
        int is_system
        PPCODE:
        USER__ENT *ent;
        ent = lu_ent_new();
        lu_group_default(self, name, is_system, ent);
        XPUSHs(sv_2mortal(sv_bless(newRV_noinc(newSViv(ent)), gv_stashpv("USER::ENT", 1))));

AV *
Admin_EnumerateUsersByGroup(self, name)
        USER::ADMIN *self
        char *name
        CODE:
        int c;
        USER__ERR *error = NULL;
        RETVAL = (AV*)sv_2mortal((SV*)newAV());
        GValueArray *results;
        results = lu_users_enumerate_by_group(self, name, &error);
        for (c = 0; (results != NULL) && (c < results->n_values); c++) {
                if( av_store(RETVAL, c, newSVpv(g_value_get_string(g_value_array_get_nth(results, c)), 0)) == NULL ){
                        warn("XS_UsersEnumerateFull: failed to store elems");
                }
        }
        g_value_array_free(results);
        OUTPUT:
        RETVAL

AV *
Admin_EnumerateGroupsByUser(self, name)
        USER::ADMIN *self
        char *name
        CODE:
        int c;
        USER__ERR *error = NULL;
        RETVAL = (AV*)sv_2mortal((SV*)newAV());
        GValueArray *results;
        results = lu_groups_enumerate_by_user(self, name, &error);
        for (c = 0; (results != NULL) && (c < results->n_values); c++) {
                if( av_store(RETVAL, c, newSVpv(g_value_get_string(g_value_array_get_nth(results, c)), 0)) == NULL ){
                        warn("XS_UsersEnumerateFull: failed to store elems");
                }
        }
        g_value_array_free(results);
        OUTPUT:
        RETVAL

AV * 
Admin_UsersEnumerate(self)
        USER::ADMIN *self
        CODE:
        int c;
        USER__ERR *error = NULL;
        const char *pattern = NULL;
        RETVAL = (AV*)sv_2mortal((SV*)newAV());
        GValueArray *users;
        users = lu_users_enumerate(self, pattern, &error);
        for (c = 0; ( users != NULL) && (c < users->n_values); c++) {
                if( av_store(RETVAL, c, newSVpv(g_value_get_string(g_value_array_get_nth(users, c)), 0)) == NULL ){
                        warn("XS_UserEnumerate: failed to store elements of array");
                }
        }
        g_value_array_free(users);
        OUTPUT:
        RETVAL

AV * 
Admin_GroupsEnumerate(self)
        USER::ADMIN *self
        CODE:
        int c;
        USER__ERR *error = NULL;
        const char *pattern = NULL;
        RETVAL = (AV*)sv_2mortal((SV*)newAV());
        GValueArray *groups;
        groups = lu_groups_enumerate(self, pattern, &error);
        for (c = 0; (groups != NULL) && (c < groups->n_values); c++) {
                if( av_store(RETVAL, c, newSVpv(g_value_get_string(g_value_array_get_nth(groups, c)), 0)) == NULL ){
                        warn("XS_GroupEnumerate: failed to store elements of array");
                }
        }
        g_value_array_free(groups);
        OUTPUT:
        RETVAL

AV *
Admin_UsersEnumerateFull(self)
        USER::ADMIN *self
        CODE:
        int c;
        USER__ERR *error = NULL;
        const char *pattern = NULL;
        RETVAL = (AV*)sv_2mortal((SV*)newAV());
        GPtrArray *accounts;
        accounts = lu_users_enumerate_full(self, pattern, &error);
        for (c = 0; (accounts != NULL) && (c < accounts->len); c++) {
                if( av_store(RETVAL, c, sv_bless(newRV_noinc(newSViv(g_ptr_array_index(accounts, c))), gv_stashpv("USER::ENT", 1))) == NULL ){
                        warn("XS_UsersEnumerateFull: failed to store elems");
                }
        }
        g_ptr_array_free(accounts, TRUE);
        OUTPUT:
        RETVAL

AV * 
Admin_GroupsEnumerateFull(self)
        USER::ADMIN *self
        CODE:
        int c;
        USER__ERR *error = NULL;
        const char *pattern = NULL;
        RETVAL = (AV*)sv_2mortal((SV*)newAV());
        GPtrArray *accounts;
        accounts = lu_groups_enumerate_full(self, pattern, &error);
        for (c = 0; (accounts != NULL) && (c < accounts->len); c++) {
                if( av_store(RETVAL, c, sv_bless(newRV_noinc(newSViv(g_ptr_array_index(accounts, c))), gv_stashpv("USER::ENT", 1))) == NULL ){
                        warn("XS_UsersEnumerateFull: failed to store elems");
                }
        }
        g_ptr_array_free(accounts, TRUE);
        OUTPUT:
        RETVAL

AV *
Admin_GetUserShells(self)        
        USER::ADMIN *self
        CODE:
        int i = 0;
        const char *shell;
        RETVAL = (AV*)sv_2mortal((SV*)newAV());
        setusershell(); 
        while ((shell = getusershell()) != NULL) {
                av_store(RETVAL, i, newSVpv(shell, 0));
                i++;
        }
        endusershell();
        OUTPUT:
        RETVAL

void
Admin_CleanHome(self, ent)
        USER::ADMIN *self
        USER::ENT *ent
        PPCODE:
        USER__ERR *error = NULL;
        GValueArray *values; 
        GValue *value; 
        const char *tmp = NULL;
        values = lu_ent_get(ent, LU_HOMEDIRECTORY);
        if ((values == NULL) || (values->n_values == 0)) {
             warn(_("No home directory for the user.\n"));
        } else {
                value = g_value_array_get_nth(values, 0);
                tmp = g_value_get_string(value);
                if (lu_homedir_remove(tmp, &error) == FALSE) {
                        if (error->code == lu_error_stat)
                             warn(_("Home Directory Could Not be deleted: '%s'.\n"), error ? error->string : "Unknown error");
                        else
                             croak(_("Home Directory Could Not be deleted: '%s'.\n"), error ? error->string : "Unknown error");
                }
        }

void
Admin_CleanSpool(self, ent)
        USER::ADMIN *self
        USER::ENT *ent
        USER__ERR *error = NULL;
        PPCODE:
        if (lu_mail_spool_remove(self, ent, &error) != 1) {
                warn(_("Error deleting mail spool: %s\n"), error ? error->string : "Unknown error");
        }

MODULE = USER   PACKAGE = USER::ENT    PREFIX = Ent_

USER::ENT *
Ent_new (CLASS)
        char *CLASS
        CODE:
        RETVAL = (USER__ENT *)lu_ent_new();
        if( RETVAL == NULL ){
                warn("unable to malloc USER__ENT");
                XSRETURN_UNDEF;
        }
        OUTPUT:
        RETVAL

void
Ent_DESTROY(self)
        USER::ENT *self
        CODE:
        if (self) lu_ent_free(self);

void
Ent_EntType(self)
        USER::ENT *self
        PPCODE:
        switch (self->type) {
                case lu_invalid:
                        break;
                case lu_user:
                        XPUSHs(sv_2mortal(newSVpv("user", 0)));
                        break;
                case lu_group:
                        XPUSHs(sv_2mortal(newSVpv("group", 0)));
                        break;
                default:
                        break;
        }
        
void 
Ent_UserName(self, ssv)
        USER::ENT *self
        SV * ssv
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) && SvIV(ssv) == -65533) {
                values = lu_ent_get(self, LU_USERNAME);
                if (values != NULL) {
                        value = g_value_array_get_nth(values, 0);
                        if (G_VALUE_HOLDS_STRING(value)) {
                                XPUSHs(sv_2mortal(newSVpv(g_value_get_string(value), 0)));
                        } else if (G_VALUE_HOLDS_LONG(value)) {
                                XPUSHs(sv_2mortal(newSVpv(g_strdup_printf("%ld", g_value_get_long(value)), 0)));
                        }
                }
        } else if( SvPOK( ssv ) ) {
                memset(&val, 0, sizeof(val));
                g_value_init(&val, G_TYPE_STRING);
                g_value_set_string(&val, SvPV(ssv,PL_na));
                lu_ent_clear(self, LU_USERNAME);
                lu_ent_add(self, LU_USERNAME, &val);
        } else {
                warn("XS_UserName: Cannot make operation on  LU_USERNAME attribute");
        }

void 
Ent_GroupName(self, ssv)
        USER::ENT *self
        SV * ssv
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) && SvIV(ssv) == -65533) {
                values = lu_ent_get(self, LU_GROUPNAME);
                if (values != NULL) {
                        value = g_value_array_get_nth(values, 0);
                        if (G_VALUE_HOLDS_STRING(value)) {
                        XPUSHs(sv_2mortal(newSVpv(g_value_get_string(value), 0)));
                        } else if (G_VALUE_HOLDS_LONG(value)) {
                                XPUSHs(sv_2mortal(newSVpv(g_strdup_printf("%ld", g_value_get_long(value)), 0)));
                        }
                }
        } else if( SvPOK( ssv ) ) {
                memset(&val, 0, sizeof(val));
                g_value_init(&val, G_TYPE_STRING);
                g_value_set_string(&val, SvPV(ssv,PL_na));
                lu_ent_clear(self, LU_GROUPNAME);
                lu_ent_add(self, LU_GROUPNAME, &val);
        } else {
                warn("XS_GroupName: Cannot make operation on LU_GROUPNAME attribute");
        }

AV*
Ent_MemberName(self, rv, AddOrDel)
        USER::ENT *self
        SV *rv
        int AddOrDel
        CODE:
        GValueArray *members;
        GValue *value, val;
        RETVAL = (AV*)sv_2mortal((SV*)newAV());
        char *member = NULL;
        int c;
        if ( SvIOK(rv) && SvIV(rv) == 1) {
                members = lu_ent_get(self, LU_MEMBERNAME);
                for (c = 0; (members != NULL) && (c < members->n_values); c++) {
                        if( av_store(RETVAL, c, newSVpv(g_value_get_string(g_value_array_get_nth(members, c)), 0)) == NULL ){
                                warn("XS_MemberName: failed to store elements of array");
                        }
                }
        } else if ( SvPOK( rv ) ) {
                memset(&val, 0, sizeof(val));
                g_value_init(&val, G_TYPE_STRING);
                member = SvPV(rv, PL_na);
                g_value_set_string(&val, member);
                if (AddOrDel == 1) {
                        lu_ent_add(self, LU_MEMBERNAME, &val);
                } else if (AddOrDel == 2) {
                        lu_ent_del(self, LU_MEMBERNAME, &val);
                }
                g_value_reset(&val);
        } else {
                croak("XS_MemberName: Cannot make operation on LU_MEMBERNAME attribute");
        };
        OUTPUT:
        RETVAL
        
void 
Ent_Uid(self, ssv)
        USER::ENT *self
        SV *ssv;
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) ) {
                if (SvIV(ssv) == -65533) {
                        values = lu_ent_get(self, LU_UIDNUMBER);
                        if (values != NULL) {
                                value = g_value_array_get_nth(values, 0);
                                if (G_VALUE_HOLDS_LONG(value)) {
                                        XPUSHs(sv_2mortal(newSViv(g_value_get_long(value))));
                                } else if (G_VALUE_HOLDS_STRING(value)) {
                                        XPUSHs(sv_2mortal(newSViv(atol(g_value_get_string(value)))));
                                }
                        }
                } else {
                        memset(&val, 0, sizeof(val));
                        g_value_init(&val, G_TYPE_LONG);
                        g_value_set_long(&val, (long)SvIV( ssv ));
                        lu_ent_clear(self, LU_UIDNUMBER);
                        lu_ent_add(self, LU_UIDNUMBER, &val);
                }
        } else {
                warn("XS_Uid: Cannot make operation on LU_UIDNUMBER attribute");
        }

void
Ent_Gid(self, ssv)
        USER::ENT *self
        SV *ssv;
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) ) { 
                if (SvIV(ssv) == -65533) {
                        values = lu_ent_get(self, LU_GIDNUMBER);
                        if (values != NULL) {
                                value = g_value_array_get_nth(values, 0);
                                if (G_VALUE_HOLDS_LONG(value)) {
                                        XPUSHs(sv_2mortal(newSViv(g_value_get_long(value))));
                                } else if (G_VALUE_HOLDS_STRING(value)) {
                                        XPUSHs(sv_2mortal(newSViv(atol(g_value_get_string(value)))));
                                }
                        }
                } else {
                        memset(&val, 0, sizeof(val));
                        g_value_init(&val, G_TYPE_LONG);
                        g_value_set_long(&val, (long)SvIV( ssv ));
                        lu_ent_clear(self, LU_GIDNUMBER);
                        lu_ent_add(self, LU_GIDNUMBER, &val);
                }
        } else {
                warn("XS_Gid: Cannot make operation on LU_GIDNUMBER attribute");
        }

void 
Ent_Gecos(self, ssv)
        USER::ENT *self
        SV *ssv;
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) && SvIV(ssv) == -65533) {
                values = lu_ent_get(self, LU_GECOS);
                if (values != NULL) {
                        value = g_value_array_get_nth(values, 0);
                        if (G_VALUE_HOLDS_STRING(value)) {
                                XPUSHs(sv_2mortal(newSVpv(g_value_get_string(value), 0)));
                        } else if (G_VALUE_HOLDS_LONG(value)) {
                                XPUSHs(sv_2mortal(newSVpv(g_strdup_printf("%ld", g_value_get_long(value)), 0)));
                        }
                }
        } else if( SvPOK( ssv ) ) {
                memset(&val, 0, sizeof(val));
                g_value_init(&val, G_TYPE_STRING);
                g_value_set_string(&val, SvGChar(ssv));
                lu_ent_clear(self, LU_GECOS);
                lu_ent_add(self, LU_GECOS, &val);
        } else {
                warn("XS_Gecos: Cannot make operation on LU_GECOS attribute");
        }

void 
Ent_HomeDir(self, ssv)
        USER::ENT *self
        SV *ssv
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) && SvIV(ssv) == -65533) {
                values = lu_ent_get(self, LU_HOMEDIRECTORY);
                if (values != NULL) {
                        value = g_value_array_get_nth(values, 0);
                        if (G_VALUE_HOLDS_STRING(value)) {
                        XPUSHs(sv_2mortal(newSVpv(g_value_get_string(value), 0)));
                        } else if (G_VALUE_HOLDS_LONG(value)) {
                                XPUSHs(sv_2mortal(newSVpv(g_strdup_printf("%ld", g_value_get_long(value)), 0)));
                        }
                }
        } else if( SvPOK( ssv ) ) {
                memset(&val, 0, sizeof(val));
                g_value_init(&val, G_TYPE_STRING);
                g_value_set_string(&val, SvPV(ssv,PL_na));
                lu_ent_clear(self, LU_HOMEDIRECTORY);
                lu_ent_add(self, LU_HOMEDIRECTORY, &val);
        } else {
                warn("XS_HomeDir: Cannot make operation on LU_HOMEDIRECTORY attribute");
        }

void 
Ent_LoginShell(self, ssv)
        USER::ENT *self
        SV *ssv
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) && SvIV(ssv) == -65533) {
                values = lu_ent_get(self, LU_LOGINSHELL);
                if (values != NULL) {
                        value = g_value_array_get_nth(values, 0);
                        if (G_VALUE_HOLDS_STRING(value)) {
                        XPUSHs(sv_2mortal(newSVpv(g_value_get_string(value), 0)));
                        } else if (G_VALUE_HOLDS_LONG(value)) {
                                XPUSHs(sv_2mortal(newSVpv(g_strdup_printf("%ld", g_value_get_long(value)), 0)));
                        }
                }
        } else if( SvPOK( ssv ) ) {
                memset(&val, 0, sizeof(val));
                g_value_init(&val, G_TYPE_STRING);
                g_value_set_string(&val, SvPV(ssv,PL_na));
                lu_ent_clear(self, LU_LOGINSHELL);
                lu_ent_add(self, LU_LOGINSHELL, &val);
        } else {
                warn("XS_LoginShell: Cannot make operation on LU_LOGINSHELL attribute");
        }

void 
Ent_ShadowPass(self, ssv)
        USER::ENT *self
        SV *ssv
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) && SvIV(ssv) == -65533) {
                values = lu_ent_get(self, LU_SHADOWPASSWORD);
                if (values != NULL) {
                        value = g_value_array_get_nth(values, 0);
                        if (G_VALUE_HOLDS_STRING(value)) {
                        XPUSHs(sv_2mortal(newSVpv(g_value_get_string(value), 0)));
                        } else if (G_VALUE_HOLDS_LONG(value)) {
                                XPUSHs(sv_2mortal(newSVpv(g_strdup_printf("%ld", g_value_get_long(value)), 0)));
                        }
                }
        } else if( SvPOK( ssv ) ) {
                memset(&val, 0, sizeof(val));
                g_value_init(&val, G_TYPE_STRING);
                g_value_set_string(&val, SvPV(ssv,PL_na));
                lu_ent_clear(self, LU_SHADOWPASSWORD);
                lu_ent_add(self, LU_SHADOWPASSWORD, &val);
        } else {
                warn("XS_ShadowPass: Cannot make operation on LU_SHADOWPASSWORD attribute");
        }

void 
Ent_ShadowWarn(self, ssv)
        USER::ENT *self
        SV *ssv
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) ) {
                if (SvIV(ssv) == -65533) {
                        values = lu_ent_get(self, LU_SHADOWWARNING);
                        if (values != NULL) {
                                value = g_value_array_get_nth(values, 0);
                                if (G_VALUE_HOLDS_LONG(value)) {
                                        XPUSHs(sv_2mortal(newSViv(g_value_get_long(value))));
                                } else if (G_VALUE_HOLDS_STRING(value)) {
                                        XPUSHs(sv_2mortal(newSViv(atol(g_value_get_string(value)))));
                                }
                        }
                } else {
                        memset(&val, 0, sizeof(val));
                        g_value_init(&val, G_TYPE_LONG);
                        g_value_set_long(&val, (long)SvIV( ssv ));
                        lu_ent_clear(self, LU_SHADOWWARNING);
                        lu_ent_add(self, LU_SHADOWWARNING, &val);
                }
        } else {
                warn("XS_ShadowWarn: Cannot make operation on LU_SHADOWWARNING attribute");
        }

void 
Ent_ShadowLastChange(self, ssv)
        USER::ENT *self
        SV *ssv
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) ) {
                if (SvIV(ssv) == -65533) {
                        values = lu_ent_get(self, LU_SHADOWLASTCHANGE);
                        if (values != NULL) {
                                value = g_value_array_get_nth(values, 0);
                                if (G_VALUE_HOLDS_LONG(value)) {
                                        XPUSHs(sv_2mortal(newSViv(g_value_get_long(value))));
                                } else if (G_VALUE_HOLDS_STRING(value)) {
                                        XPUSHs(sv_2mortal(newSViv(atol(g_value_get_string(value)))));
                                }
                        }
                } else {
                        memset(&val, 0, sizeof(val));
                        g_value_init(&val, G_TYPE_LONG);
                        g_value_set_long(&val, (long)SvIV( ssv ));
                        lu_ent_clear(self, LU_SHADOWLASTCHANGE);
                        lu_ent_add(self, LU_SHADOWLASTCHANGE, &val);
                }
        } else {
                warn("XS_ShadowLastChange: Cannot make operation on LU_SHADOWLASTCHANGE attribute");
        }

void 
Ent_ShadowMin(self, ssv)
        USER::ENT *self
        SV *ssv
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) ) {
                if (SvIV(ssv) == -65533) {        
                        values = lu_ent_get(self, LU_SHADOWMIN);
                        if (values != NULL) {
                                value = g_value_array_get_nth(values, 0);
                                if (G_VALUE_HOLDS_LONG(value)) {
                                        XPUSHs(sv_2mortal(newSViv(g_value_get_long(value))));
                                } else if (G_VALUE_HOLDS_STRING(value)) {
                                        XPUSHs(sv_2mortal(newSViv(atol(g_value_get_string(value)))));
                                }
                        }
                } else {
                        memset(&val, 0, sizeof(val));
                        g_value_init(&val, G_TYPE_LONG);
                        g_value_set_long(&val, (long)SvIV( ssv ));
                        lu_ent_clear(self, LU_SHADOWMIN);
                        lu_ent_add(self, LU_SHADOWMIN, &val);
                }
        } else {
                warn("XS_ShadowMin: Cannot make operation on LU_SHADOWMIN attribute");
        }

void 
Ent_ShadowMax(self, ssv)
        USER::ENT *self
        SV *ssv
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) ) {
                if (SvIV(ssv) == -65533) {
                        values = lu_ent_get(self, LU_SHADOWMAX);
                        if (values != NULL) {
                                value = g_value_array_get_nth(values, 0);
                                if (G_VALUE_HOLDS_LONG(value)) {
                                        XPUSHs(sv_2mortal(newSViv(g_value_get_long(value))));
                                } else if (G_VALUE_HOLDS_STRING(value)) {
                                        XPUSHs(sv_2mortal(newSViv(atol(g_value_get_string(value)))));
                                }
                        }
                } else {
                        memset(&val, 0, sizeof(val));
                        g_value_init(&val, G_TYPE_LONG);
                        g_value_set_long(&val, (long)SvIV( ssv ));
                        lu_ent_clear(self, LU_SHADOWMAX);
                        lu_ent_add(self, LU_SHADOWMAX, &val);
                }
        } else {
                warn("XS_ShadowMax: Cannot make operation on LU_SHADOWMAX attribute");
        }

void 
Ent_ShadowInact(self, ssv)
        USER::ENT *self
        SV *ssv
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) ) {
                if (SvIV(ssv) == -65533) {
                        values = lu_ent_get(self, LU_SHADOWINACTIVE);
                        if (values != NULL) {
                                value = g_value_array_get_nth(values, 0);
                                if (G_VALUE_HOLDS_LONG(value)) {
                                        XPUSHs(sv_2mortal(newSViv(g_value_get_long(value))));
                                } else if (G_VALUE_HOLDS_STRING(value)) {
                                        XPUSHs(sv_2mortal(newSViv(atol(g_value_get_string(value)))));
                                }
                        }
                } else {
                        memset(&val, 0, sizeof(val));
                        g_value_init(&val, G_TYPE_LONG);
                        g_value_set_long(&val, (long)SvIV( ssv ));
                        lu_ent_clear(self, LU_SHADOWINACTIVE);
                        lu_ent_add(self, LU_SHADOWINACTIVE, &val);
                }
        } else {
                warn("XS_ShadowInact: Cannot make operation on LU_SHADOWINACTIVE attribute");
        }

void 
Ent_ShadowExpire(self, ssv)
        USER::ENT *self
        SV *ssv
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) ) {
                if (SvIV(ssv) == -65533) {
                        values = lu_ent_get(self, LU_SHADOWEXPIRE);
                        if (values != NULL) {
                                value = g_value_array_get_nth(values, 0);
                                if (G_VALUE_HOLDS_LONG(value)) {
                                        XPUSHs(sv_2mortal(newSViv(g_value_get_long(value))));
                                } else if (G_VALUE_HOLDS_STRING(value)) {
                                        XPUSHs(sv_2mortal(newSViv(atol(g_value_get_string(value)))));
                                }
                        }
                }
        } else if (SvNOK(ssv)) {
                memset(&val, 0, sizeof(val));
                g_value_init(&val, G_TYPE_LONG);
                g_value_set_long(&val, (long)SvNV( ssv ));
                lu_ent_clear(self, LU_SHADOWEXPIRE);
                lu_ent_add(self, LU_SHADOWEXPIRE, &val);
        } else {
                warn("XS_ShadowExpire: Cannot make operation on LU_SHADOWEXPIRE attribute");
        }

void 
Ent_ShadowFlag(self, ssv)
        USER::ENT *self
        SV *ssv
        PPCODE:
        GValueArray *values;
        GValue *value, val;
        if ( SvIOK(ssv) ) {
                if ( SvIV(ssv) == -65533 ) {
                        values = lu_ent_get(self, LU_SHADOWFLAG);
                        if (values != NULL) {
                                value = g_value_array_get_nth(values, 0);
                                if (G_VALUE_HOLDS_LONG(value)) {
                                        XPUSHs(sv_2mortal(newSViv(g_value_get_long(value))));
                                } else if (G_VALUE_HOLDS_STRING(value)) {
                                        XPUSHs(sv_2mortal(newSViv(atol(g_value_get_string(value)))));
                                }
                        }
                } else {
                        memset(&val, 0, sizeof(val));
                        g_value_init(&val, G_TYPE_LONG);
                        g_value_set_long(&val, (long)SvIV( ssv ));
                        lu_ent_clear(self, LU_SHADOWFLAG);
                        lu_ent_add(self, LU_SHADOWFLAG, &val);
                }
        } else {
                warn("XS_ShadowExpire: Cannot make operation on LU_SHADOWEXPIRE attribute");
        }

MODULE = USER       PACKAGE = USER         PREFIX = User_
	
void
User_ReadConfigFiles()
        CODE:
        /*force read of /etc/sysconfig/userdrakefilter*/
        
