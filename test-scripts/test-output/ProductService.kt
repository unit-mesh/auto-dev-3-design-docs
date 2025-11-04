package com.example.service

import kotlinx.serialization.Serializable
import java.math.BigDecimal

/**
 * Product data class representing a product entity
 *
 * @property id Unique product identifier
 * @property name Product name
 * @property price Product price
 * @property description Product description
 * @property category Product category
 */
@Serializable
data class Product(
    val id: String,
    val name: String,
    val price: BigDecimal,
    val description: String,
    val category: String
) {
    /**
     * Validates product data
     */
    fun isValid(): Boolean {
        return id.isNotBlank() &&
               name.isNotBlank() &&
               price > BigDecimal.ZERO &&
               description.isNotBlank() &&
               category.isNotBlank()
    }

    /**
     * Gets formatted price string
     */
    fun getFormattedPrice(): String = \