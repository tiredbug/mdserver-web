# coding: utf-8


import sqlite3
import os
import sys


class Sql():
    __DB_FILE = None
    __DB_CONN = None
    __DB_TABLE = ""
    __OPT_WHERE = ""
    __OPT_LIMIT = ""
    __OPT_GROUP = ""
    __OPT_ORDER = ""
    __OPT_FIELD = "*"
    __OPT_PARAM = ()

    def __init__(self):
        self.__DB_FILE = 'data/default.db'

    def __GetConn(self):
        try:
            if self.__DB_CONN == None:
                self.__DB_CONN = sqlite3.connect(self.__DB_FILE)
                self.__DB_CONN.text_factory = str
        except Exception as ex:
            return "error: " + str(ex)

    def autoTextFactory(self):
        if sys.version_info[0] == 3:
            self.__DB_CONN.text_factory = lambda x: str(
                x, encoding="utf-8", errors='ignore')
        else:
            self.__DB_CONN.text_factory = lambda x: unicode(
                x, "utf-8", "ignore")

    def dbfile(self, name):
        self.__DB_FILE = 'data/' + name + '.db'
        return self

    def dbPos(self, path, name):
        self.__DB_FILE = path + '/' + name + '.db'
        return self

    def table(self, table):
        self.__DB_TABLE = table
        return self

    def where(self, where, param):
        if where:
            self.__OPT_WHERE = " WHERE " + where
            self.__OPT_PARAM = param
        return self

    def andWhere(self, where, param):
        if where:
            self.__OPT_WHERE = self.__OPT_WHERE + " and " + where
            self.__OPT_PARAM = self.__OPT_PARAM + param
        return self

    def order(self, order):
        if len(order):
            self.__OPT_ORDER = " ORDER BY " + order
        else:
            self.__OPT_ORDER = ""
        return self

    def group(self, group):
        if len(group):
            self.__OPT_GROUP = " GROUP BY " + group
        else:
            self.__OPT_GROUP = ""
        return self

    def limit(self, limit):
        if len(limit):
            self.__OPT_LIMIT = " LIMIT " + limit
        else:
            self.__OPT_LIMIT = ""
        return self

    def field(self, field):
        if len(field):
            self.__OPT_FIELD = field
        return self

    def select(self):
        self.__GetConn()
        try:
            sql = "SELECT " + self.__OPT_FIELD + " FROM " + self.__DB_TABLE + \
                self.__OPT_WHERE + self.__OPT_GROUP + self.__OPT_ORDER + self.__OPT_LIMIT
            result = self.__DB_CONN.execute(sql, self.__OPT_PARAM)
            data = result.fetchall()
            if self.__OPT_FIELD != "*":
                field = self.__OPT_FIELD.split(',')
                tmp = []
                for row in data:
                    i = 0
                    tmp1 = {}
                    for key in field:
                        tmp1[key] = row[i]
                        i += 1
                    tmp.append(tmp1)
                    del(tmp1)
                data = tmp
                del(tmp)
            else:
                tmp = map(list, data)
                data = tmp
                del(tmp)
            self.__close()
            return data
        except Exception as ex:
            return "error: " + str(ex)

    def inquiry(self, input_field=''):
        self.__GetConn()
        try:
            sql = "SELECT " + self.__OPT_FIELD + " FROM " + self.__DB_TABLE + \
                self.__OPT_WHERE + self.__OPT_GROUP + self.__OPT_ORDER + self.__OPT_LIMIT
            result = self.__DB_CONN.execute(sql, self.__OPT_PARAM)
            data = result.fetchall()
            if self.__OPT_FIELD != "*":

                if input_field != "":
                    field = input_field.split(',')
                else:
                    field = self.__OPT_FIELD.split(',')

                tmp = []
                for row in data:
                    i = 0
                    tmp1 = {}
                    for key in field:
                        tmp1[key] = row[i]
                        i += 1
                    tmp.append(tmp1)
                    del(tmp1)
                data = tmp
                del(tmp)
            else:
                tmp = map(list, data)
                data = tmp
                del(tmp)
            return data
        except Exception as ex:
            return "error: " + str(ex)

    def getField(self, keyName):
        result = self.field(keyName).select()
        if len(result) == 1:
            return result[0][keyName]
        return result

    def setField(self, keyName, keyValue):
        return self.save(keyName, (keyValue,))

    def find(self):
        result = self.limit("1").select()
        if len(result) == 1:
            return result[0]
        return result

    def count(self):
        key = "COUNT(*)"
        data = self.field(key).select()
        try:
            return int(data[0][key])
        except:
            return 0

    def add(self, keys, param):
        self.__GetConn()
        try:
            values = ""
            for key in keys.split(','):
                values += "?,"
            values = self.checkInput(values[0:len(values) - 1])
            sql = "INSERT INTO " + self.__DB_TABLE + \
                "(" + keys + ") " + "VALUES(" + values + ")"
            result = self.__DB_CONN.execute(sql, param)
            last_id = result.lastrowid
            self.__close()
            self.__DB_CONN.commit()
            return last_id
        except Exception as ex:
            return "error: " + str(ex)

    def checkInput(self, data):
        if not data:
            return data
        if type(data) != str:
            return data
        checkList = [
            {'d': '<', 'r': '＜'},
            {'d': '>', 'r': '＞'},
            {'d': '\'', 'r': '‘'},
            {'d': '"', 'r': '“'},
            {'d': '&', 'r': '＆'},
            {'d': '#', 'r': '＃'},
            {'d': '<', 'r': '＜'}
        ]
        for v in checkList:
            data = data.replace(v['d'], v['r'])
        return data

    def addAll(self, keys, param):
        self.__GetConn()
        try:
            values = ""
            for key in keys.split(','):
                values += "?,"
            values = values[0:len(values) - 1]
            sql = "INSERT INTO " + self.__DB_TABLE + \
                "(" + keys + ") " + "VALUES(" + values + ")"
            result = self.__DB_CONN.execute(sql, param)
            return True
        except Exception as ex:
            return "error: " + str(ex)

    def commit(self):
        self.__close()
        self.__DB_CONN.commit()

    def save(self, keys, param):
        self.__GetConn()
        try:
            opt = ""
            for key in keys.split(','):
                opt += key + "=?,"
            opt = opt[0:len(opt) - 1]
            sql = "UPDATE " + self.__DB_TABLE + " SET " + opt + self.__OPT_WHERE

            tmp = list(param)
            for arg in self.__OPT_PARAM:
                tmp.append(arg)
            self.__OPT_PARAM = tuple(tmp)
            result = self.__DB_CONN.execute(sql, self.__OPT_PARAM)
            self.__close()
            self.__DB_CONN.commit()
            return result.rowcount
        except Exception as ex:
            return "error: " + str(ex)

    def delete(self, id=None):
        self.__GetConn()
        try:
            if id:
                self.__OPT_WHERE = " WHERE id=?"
                self.__OPT_PARAM = (id,)
            sql = "DELETE FROM " + self.__DB_TABLE + self.__OPT_WHERE
            result = self.__DB_CONN.execute(sql, self.__OPT_PARAM)
            self.__close()
            self.__DB_CONN.commit()
            return result.rowcount
        except Exception as ex:
            return "error: " + str(ex)

    def originExecute(self, sql, param=()):
        self.__GetConn()
        try:
            result = self.__DB_CONN.execute(sql, param)
            self.__DB_CONN.commit()
            return result
        except Exception as ex:
            return "error: " + str(ex)

    def execute(self, sql, param=()):
        self.__GetConn()
        try:
            result = self.__DB_CONN.execute(sql, param)
            self.__DB_CONN.commit()
            return result.rowcount
        except Exception as ex:
            return "error: " + str(ex)

    def query(self, sql, param):
        self.__GetConn()
        try:
            result = self.__DB_CONN.execute(sql, param)
            return result
        except Exception as ex:
            return "error: " + str(ex)

    def create(self, name):
        self.__GetConn()
        import slemp
        script = slemp.readFile('data/' + name + '.sql')
        result = self.__DB_CONN.executescript(script)
        self.__DB_CONN.commit()
        return result.rowcount

    def fofile(self, filename):
        self.__GetConn()
        import slemp
        script = slemp.readFile(filename)
        result = self.__DB_CONN.executescript(script)
        self.__DB_CONN.commit()
        return result.rowcount

    def __close(self):
        self.__OPT_WHERE = ""
        self.__OPT_FIELD = "*"
        self.__OPT_ORDER = ""
        self.__OPT_LIMIT = ""
        self.__OPT_PARAM = ()

    def close(self):
        try:
            self.__DB_CONN.close()
            self.__DB_CONN = None
        except:
            pass
