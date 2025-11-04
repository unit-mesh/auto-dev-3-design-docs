package com.example.service

import kotlinx.coroutines.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/**
 * User data class representing a user entity
 * 
 * @property id Unique user identifier
 * @property username User's username
 * @property email User's email address
 * @property fullName User's full name
 * @property createdAt Creation timestamp
 * @property isActive Whether the user is active
 */
@Serializable
data class User(
    val id: String,
    val username: String,
    val email: String,
    val fullName: String,
    val createdAt: String,
    val isActive: Boolean = true
) {
    /**
     * Validates user data
     * 
     * @return true if user data is valid, false otherwise
     */
    fun isValid(): Boolean {
        return id.isNotBlank() && 
               username.isNotBlank() && 
               email.isNotBlank() && 
               email.contains('@') && 
               email.contains('.') &&
               fullName.isNotBlank() &&
               createdAt.isNotBlank()
    }
    
    /**
     * Gets user display name
     */
    fun getDisplayName(): String = fullName.ifBlank { username }
    
    /**
     * Checks if user was created recently (within last 24 hours)
     */
    fun isNewUser(): Boolean {
        return try {
            val created = LocalDateTime.parse(createdAt, DateTimeFormatter.ISO_LOCAL_DATE_TIME)
            val now = LocalDateTime.now()
            created.isAfter(now.minusDays(1))
        } catch (e: Exception) {
            false
        }
    }
    
    companion object {
        /**
         * Creates a new user with current timestamp
         */
        fun create(username: String, email: String, fullName: String): User {
            return User(
                id = generateId(),
                username = username,
                email = email,
                fullName = fullName,
                createdAt = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
            )
        }
        
        private fun generateId(): String {
            return \