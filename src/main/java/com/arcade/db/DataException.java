package com.arcade.db;

/** Unchecked wrapper so MySQL (SQLException) and MongoDB errors look the same to the servlets. */
public class DataException extends RuntimeException {
    private static final long serialVersionUID = 1L;
    public DataException(String msg, Throwable cause) { super(msg, cause); }
}
